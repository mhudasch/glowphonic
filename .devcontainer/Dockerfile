FROM debian:bullseye-slim

ARG ZIG_VERSION=0.14.0

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    build-essential \
    libssl-dev \
    pkg-config \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN wget https://ziglang.org/download/$ZIG_VERSION/zig-linux-x86_64-$ZIG_VERSION.tar.xz \
    && tar -xf zig-linux-x86_64-$ZIG_VERSION.tar.xz \
    && mv zig-linux-x86_64-$ZIG_VERSION /usr/local/zig \
    && rm zig-linux-x86_64-$ZIG_VERSION.tar.xz

ENV PATH="/usr/local/zig:${PATH}"

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

#RUN apt-get update && apt-get install -y \
#    libasound2-dev \
#    libpulse-dev \
#    libsndfile1-dev \
#    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

USER $USERNAME