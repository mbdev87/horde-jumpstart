# Helix Core (Perforce) server for the sandbox. Unlicensed p4d is free for
# small teams (<= ~20 concurrent users), plenty for a personal microverse.
# P4_VERSION is pinned so rebuilds are reproducible; bump it deliberately.
# (Note: newer releases dropped the raw linux bin dirs from cdist2; r25.1 is the newest that serves them.)
ARG P4_VERSION=r25.1

FROM ubuntu:22.04
ARG P4_VERSION
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates procps && \
    rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /usr/local/bin/p4d https://cdist2.perforce.com/perforce/${P4_VERSION}/bin.linux26x86_64/p4d && \
    curl -fsSL -o /usr/local/bin/p4   https://cdist2.perforce.com/perforce/${P4_VERSION}/bin.linux26x86_64/p4 && \
    chmod +x /usr/local/bin/p4d /usr/local/bin/p4
RUN mkdir -p /p4root
COPY init.sh /init.sh
EXPOSE 1666
CMD ["/bin/bash", "/init.sh"]
