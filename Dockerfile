FROM ubuntu:24.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# ⚠️ CHANGE THIS PASSWORD before building if security matters!
ENV VNC_PASSWORD=12345
ENV VNC_RESOLUTION=1920x1080

# Install all dependencies in ONE layer
# 🔑 Critical: tigervnc-common provides the 'vncpasswd' command
RUN apt-get update && apt-get install -y --no-install-recommends \
    tigervnc-standalone-server \
    tigervnc-tools \
    xfce4 \
    xfce4-goodies \
    dbus-x11 \
    proxychains4 \
    micro \
    wget \
    ca-certificates \
    software-properties-common \
    && add-apt-repository universe \
    && add-apt-repository multiverse \
    && apt-get update \
    && rm -rf /var/lib/apt/lists/*

# Download AND install the Teneo .deb package
# File goes to /tmp, gets installed, then deleted — nothing left behind
RUN wget -q https://github.com/TeneoProtocolAI/teneo-node-app-release-beta/releases/download/v0.4.4/Teneo.Beacon_0.4.4_amd64.deb \
    -O /tmp/teneo.deb && \
    apt-get update && \
    apt-get install -y /tmp/teneo.deb || apt-get -f install -y && \
    rm -f /tmp/teneo.deb && \
    rm -rf /var/lib/apt/lists/*

# Set up VNC password file (vncpasswd now works because tigervnc-common is installed)
RUN mkdir -p /root/.vnc && \
    echo "${VNC_PASSWORD}" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# Create VNC startup script for XFCE
RUN printf '#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec startxfce4\n' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

EXPOSE 5901

# Start VNC server and keep container alive
CMD ["sh", "-c", "rm -f /tmp/.X1-lock /tmp/.X11-unix/X1; vncserver :1 -geometry ${VNC_RESOLUTION} -depth 24 -localhost no && tail -f /dev/null"]
