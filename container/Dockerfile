FROM ghcr.io/boldsoftware/exeuntu:latest

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  bash \
  ca-certificates \
  curl \
  git \
  gh \
  jq \
  openssh-client \
  ripgrep \
  socat \
  bubblewrap \
  build-essential \
  pkg-config \
  python3 \
  python3-pip \
  unzip \
  xz-utils \
  zstd \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash agent && \
  mkdir -p /workspace && \
  chown -R agent:agent /workspace

USER agent

ENV HOME=/home/agent
ENV PATH=/home/agent/.local/bin:/usr/local/bin:/usr/bin:/bin

WORKDIR /home/agent

RUN curl -fsSL https://mise.run | sh

RUN echo 'eval "$($HOME/.local/bin/mise activate bash)"' >> /home/agent/.bashrc

RUN curl -fsSL https://claude.ai/install.sh | bash

RUN git config --global init.defaultBranch main && \
  git config --global pull.rebase false

WORKDIR /workspace

CMD ["/bin/bash"]