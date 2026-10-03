#!/bin/bash
# First-run bootstrap for the sandbox Perforce server. Idempotent across restarts.
#
# NOTE: p4d 2025.1 wants complete spec forms (its own templates) when feeding
# specs via -i, so we round-trip the server template and override fields with
# --field rather than hand-writing minimal specs.
set -uo pipefail

P4ROOT=${P4ROOT:-/p4root}
P4="p4 -p localhost:1666"
P4SUPER="p4 -p localhost:1666 -u super"
SERVICE_USER=${P4_SERVICE_USER:-horde.build}
SERVICE_PASS=${P4_SERVICE_PASSWORD:-HordeBuild123!}

p4d -r "$P4ROOT" -p 1666 -L "$P4ROOT/p4.log" &
P4D_PID=$!

# Wait until p4d answers
for i in $(seq 1 30); do
    if $P4 info >/dev/null 2>&1; then break; fi
    sleep 1
done

if [ ! -f "$P4ROOT/.sandbox-initialized" ]; then
    echo "Initializing sandbox Perforce server..."
    $P4 initialize -y

    # Service account used by Horde server and agents
    $P4SUPER user -i <<EOF
User: $SERVICE_USER
Email: $SERVICE_USER@example.com
FullName: Horde Build Service
EOF

    # Superuser password must be set via passwd; super can set it for others
    printf '%s\n%s\n' "$SERVICE_PASS" "$SERVICE_PASS" | $P4SUPER passwd "$SERVICE_USER"

    # Give it superuser on everything
    $P4SUPER protect -i <<EOF
# Sandbox access
Access:
	view: allow write user $SERVICE_USER * //...
EOF

    # Stream depot + main stream (template round-trip, see NOTE above)
    $P4SUPER --field "Description=Sandbox depot" --field "Type=stream" depot -o horde | $P4SUPER depot -i
    $P4SUPER stream -o //horde/main | sed 's|^Type:\tdevelopment|Type:\tmainline|' | $P4SUPER stream -i

    # Second stream depot mirroring the "real UE5 project" demo config
    $P4SUPER --field "Description=UE5 sample depot" --field "Type=stream" depot -o UE5 | $P4SUPER depot -i
    $P4SUPER stream -o //UE5/Release-5.8-HordeSync | sed 's|^Type:\tdevelopment|Type:\tmainline|' | $P4SUPER stream -i

    touch "$P4ROOT/.sandbox-initialized"
fi

# Seed demo content if the depot path is empty
if [ -z "$($P4 -u "$SERVICE_USER" dirs //horde/main 2>/dev/null)" ]; then
    WS=/tmp/p4-seed
    mkdir -p "$WS/BuildGraph"
    $P4 -u "$SERVICE_USER" --field "Root=$WS" --field "Stream=//horde/main" client -o p4-seeder | $P4 -u "$SERVICE_USER" client -i
    cd "$WS"
    echo "horde-jumpstart demo depot. Submit changes here to trigger Horde jobs." > README.txt
    echo "Drop BuildGraph scripts here. Milestone 4 adds the minimal graph + custom C# script node." > BuildGraph/README.txt
    $P4 -u "$SERVICE_USER" -c p4-seeder add ... 2>/dev/null
    $P4 -u "$SERVICE_USER" -c p4-seeder submit -d "Seed sandbox depot content"
fi

# Seed the UE5 sample stream (referenced by server-data/ue5.project.json)
if [ -z "$($P4 -u "$SERVICE_USER" dirs //UE5/Release-5.8-HordeSync 2>/dev/null)" ]; then
    WS=/tmp/p4-seed-ue5
    mkdir -p "$WS/Samples/Games/Lyra"
    $P4 -u "$SERVICE_USER" --field "Root=$WS" --field "Stream=//UE5/Release-5.8-HordeSync" client -o p4-seeder-ue5 | $P4 -u "$SERVICE_USER" client -i
    cd "$WS"
    echo "UE5 sample stream for the horde-jumpstart 'UE5' demo project." > README.txt
    touch Samples/Games/Lyra/Lyra.uproject
    $P4 -u "$SERVICE_USER" -c p4-seeder-ue5 add ... 2>/dev/null
    $P4 -u "$SERVICE_USER" -c p4-seeder-ue5 submit -d "Seed UE5 sample stream"
fi

echo "Perforce sandbox ready on :1666"
wait $P4D_PID
