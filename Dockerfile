FROM --platform=linux/amd64 ubuntu:22.04

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and required packages
RUN apt-get update && \
    apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    curl \
    sudo \
    apt-transport-https \
    lsb-release \
    gpg \
    xvfb \
    libglu1-mesa \
    libgtk-3-0 \
    libfuse2 \
    unzip \
    software-properties-common \
    libasound2 \
    alsa-utils \
    pulseaudio \
    libdbus-1-3 \
    libgbm1

# Print system information for debugging
RUN echo "Architecture: $(dpkg --print-architecture)" && \
    echo "OS Release: $(lsb_release -a)"

# Add Unity official repository and install Unity Hub
RUN wget -qO - https://hub.unity3d.com/linux/keys/public | gpg --dearmor | sudo tee /usr/share/keyrings/unity-hub-archive-keyring.gpg > /dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/unity-hub-archive-keyring.gpg] https://hub.unity3d.com/linux/repos/deb stable main" | sudo tee /etc/apt/sources.list.d/unity-hub.list
RUN apt-get update && apt-get install -y unityhub

# Set up display and install Unity version
RUN Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 & \
    export DISPLAY=:99 && \
    unityhub --headless install --version 2019.1.11f1 --changeset 9b001d489a54