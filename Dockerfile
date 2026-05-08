FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    VNC_PASSWORD=12345 \
    VNC_RESOLUTION=1920x1080 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install only what's essential for VNC + OpenBox + GUI app support
RUN apt-get update && apt-get install -y --no-install-recommends \
    # VNC Server
    tigervnc-standalone-server \
    tigervnc-tools \
    # Minimal WM + panel + terminal
    openbox \
    tint2 \
    pcmanfm \
    xterm \
    # GUI app dependencies (GTK/Qt basics + fonts)
    libgtk-3-0 \
    libqt5widgets5 \
    fonts-dejavu-core \
    fonts-liberation \
    # System essentials
    dbus-x11 \
    x11-xserver-utils \
    wget \
    ca-certificates \
    locales \
    proxychains4 \
    micro \
    # Cleanup
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc/* /usr/share/man/* \
    && find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en*' -exec rm -rf {} +

RUN wget -q https://github.com/TeneoProtocolAI/teneo-node-app-release-beta/releases/download/v0.4.4/Teneo.Beacon_0.4.4_amd64.deb \
    -O /tmp/teneo.deb && \
    apt-get update && \
    apt-get install -y /tmp/teneo.deb || apt-get -f install -y && \
    rm -f /tmp/teneo.deb && \
    rm -rf /var/lib/apt/lists/*

# VNC setup
RUN mkdir -p /root/.vnc && \
    echo "${VNC_PASSWORD}" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd && \
    # xstartup: launch OpenBox + tint2 panel
    printf '#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nopenbox &\ntint2 &\nwait\n' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup && \
    # VNC config
    printf 'geometry=%s\ndepth=24\nlocalhost=no\n' "${VNC_RESOLUTION}" > /root/.vnc/config

EXPOSE 5901

# Start VNC server in foreground
CMD ["sh", "-c", "rm -f /tmp/.X1-lock /tmp/.X11-unix/X1; exec vncserver :1 -fg"]
