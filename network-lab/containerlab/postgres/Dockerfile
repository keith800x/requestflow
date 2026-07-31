FROM postgres:16

# Containerlab requires the ip command to configure the routed interface.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        iproute2 \
        iputils-ping \
    && rm -rf /var/lib/apt/lists/*
