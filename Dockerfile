FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# VNC configuration (CHANGE THE PASSWORD BEFORE BUILDING!)
ENV VNC_PASSWORD=12345
ENV VNC_RESOLUTION=1920x1080

# Install VNC server, XFCE desktop, and required dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    tigervnc-standalone-server \
    xfce4 \
    xfce4-goodies \
    dbus-x11 \
    proxychains4 \
    micro \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Download and install deb package
RUN wget https://github.com/TeneoProtocolAI/teneo-node-app-release-beta/releases/download/v0.4.4/Teneo.Beacon_0.4.4_amd64.deb -O teneo.deb
RUN apt install -y ./teneo.deb

# Set up VNC password file
RUN mkdir -p /root/.vnc && \
    echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# Create VNC session startup script
RUN printf '#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec startxfce4\n' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Expose VNC port (5901 corresponds to display :1)
EXPOSE 5901

# Start VNC server and keep the container running
CMD ["sh", "-c", "rm -f /tmp/.X1-lock /tmp/.X11-unix/X1; vncserver :1 -geometry $VNC_RESOLUTION -depth 24 -localhost no && tail -f /dev/null"]
