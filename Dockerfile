FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    VNC_PASSWORD=12345 \
    VNC_RESOLUTION=1920x1080 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Verify glibc version at build time (optional debug)
RUN ldd --version | head -n1

# Install ONLY essentials for VNC + OpenBox + GUI app
RUN apt-get update && apt-get install -y --no-install-recommends \
    # VNC
    tigervnc-standalone-server \
    tigervnc-tools \
    # Minimal WM + utilities
    openbox \
    tint2 \
    autocutsel \
    pcmanfm \
    xterm \
    # GUI app runtime deps (GTK3/Qt5 basics)
    libgtk-3-0 \
    libqt5widgets5 \
    libglib2.0-0 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    # Fonts (critical for GUI rendering)
    fonts-dejavu-core \
    fonts-liberation \
    fontconfig \
    # System essentials
    micro \
    proxychains4 \
    dbus-x11 \
    x11-xserver-utils \
    wget \
    ca-certificates \
    locales \
    # Cleanup aggressively
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/icons/*/icon-theme.cache \
    && find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en*' -exec rm -rf {} + \
    && apt-get autoremove -y && apt-get clean

# VNC configuration
RUN mkdir -p /root/.vnc && \
    echo "${VNC_PASSWORD}" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd && \
    printf '#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nautocutsel -fork &\nopenbox &\ntint2 &\nwait\n' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup && \
    printf 'geometry=%s\ndepth=24\nlocalhost=no\n' "${VNC_RESOLUTION}" > /root/.vnc/config
    
# Install teneo
RUN wget -q https://github.com/TeneoProtocolAI/teneo-node-app-release-beta/releases/download/v0.4.4/Teneo.Beacon_0.4.4_amd64.deb \
    -O /tmp/teneo.deb && \
    apt-get update && \
    apt-get install -y /tmp/teneo.deb || apt-get -f install -y && \
    rm -f /tmp/teneo.deb && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 5901

# Launch VNC in foreground with proper signal handling
CMD ["sh", "-c", "rm -f /tmp/.X1-lock /tmp/.X11-unix/X1; exec vncserver :1 -fg"]
