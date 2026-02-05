ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE}

LABEL maintainer="krishbin"
LABEL description="gem5 simulator development environment"
LABEL version="0.1"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Build arguments
ARG GEM5_VERSION=v24.0
ARG TARGETARCH

# Set environment variables
ENV GEM5_HOME=/opt/gem5
ENV PATH="${GEM5_HOME}/build:${PATH}"

# Install base dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    m4 \
    scons \
    zlib1g \
    zlib1g-dev \
    libprotobuf-dev \
    protobuf-compiler \
    libprotoc-dev \
    libgoogle-perftools-dev \
    python3-dev \
    python3-pip \
    python3-pydot \
    python3-venv \
    libboost-all-dev \
    pkg-config \
    wget \
    curl \
    ca-certificates \
    libpng-dev \
    libhdf5-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir \
    scons \
    pydot \
    matplotlib \
    pyyaml \
    mypy \
    pre-commit

RUN git clone https://github.com/gem5/gem5.git ${GEM5_HOME} \
    && cd ${GEM5_HOME} \
    && git checkout ${GEM5_VERSION}

WORKDIR ${GEM5_HOME}

COPY scripts/build-gem5.sh /usr/local/bin/build-gem5.sh
RUN chmod +x /usr/local/bin/build-gem5.sh

COPY scripts/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

CMD ["/bin/bash"]
