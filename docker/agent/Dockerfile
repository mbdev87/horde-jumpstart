# Minimal Linux HordeAgent built from the engine sources staged alongside the server.
# Framework-dependent (needs the .NET 10 runtime) - the p4 client is bundled for jobs
# that sync from the sandbox Perforce.

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build-env
WORKDIR /app
COPY Binaries/ ./Binaries/
COPY Source/Programs/Horde/nuget.config ./Source/Programs/Horde/nuget.config
COPY Source/Programs/Shared/ ./Source/Programs/Shared/
COPY Source/Programs/Horde/ ./Source/Programs/Horde/
RUN dotnet publish Source/Programs/Horde/HordeAgent/HordeAgent.csproj -c Release -o out && \
    # The agent spawns "dotnet /app/JobDriver/JobDriver.dll" to run each job lease
    dotnet publish Source/Programs/Horde/Drivers/JobDriver/JobDriver.csproj -c Release -o out/JobDriver

FROM mcr.microsoft.com/dotnet/runtime:10.0 AS runtime
ARG P4_VERSION=r25.1
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /usr/local/bin/p4 https://cdist2.perforce.com/perforce/${P4_VERSION}/bin.linux26x86_64/p4 && \
    chmod +x /usr/local/bin/p4
# Jobs (and Unreal Editor) refuse to run as root on Linux; match that convention
# HOME must point somewhere writable; the agent only writes its servers.json
# registration file once GetFolderPath(LocalApplicationData) finds an existing dir.
RUN useradd -m horde && \
    mkdir -p /agent/logs "/agent/.local/share/Epic Games/Horde/Agent" && \
    chown -R horde /agent
ENV HOME=/agent
WORKDIR /app
COPY --from=build-env /app/out .
USER horde
ENTRYPOINT ["dotnet", "HordeAgent.dll"]
