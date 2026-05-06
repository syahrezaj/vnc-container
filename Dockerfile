FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV VNC_PASSWORD=12345
ENV VNC_RESOLUTION=1920x1080
ENV SSH_PASSWORD=12345

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    tigervnc-standalone-server \
    tigervnc-tools \
    xfce4 \
    xfce4-goodies \
    dbus-x11 \
    openssh-server \
    proxychains4 \
    micro \
    wget \
    ca-certificates \
    software-properties-common \
    supervisor \
    && add-apt-repository universe \
    && add-apt-repository multiverse \
    && apt-get update \
    && rm -rf /var/lib/apt/lists/*

# Download & install Teneo
RUN wget -q https://github.com/TeneoProtocolAI/teneo-node-app-release-beta/releases/download/v0.4.4/Teneo.Beacon_0.4.4_amd64.deb \
    -O /tmp/teneo.deb && \
    apt-get update && \
    apt-get install -y /tmp/teneo.deb || apt-get -f install -y && \
    rm -f /tmp/teneo.deb && \
    rm -rf /var/lib/apt/lists/*


# 🔐 Configure SSH
RUN mkdir -p /run/sshd /root/.ssh && \
    ssh-keygen -A && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "UsePAM no" >> /etc/ssh/sshd_config && \
    echo "root:${SSH_PASSWORD}" | chpasswd && \
    chmod 700 /root/.ssh

# 🖥️ Setup VNC password, startup script, and config
RUN mkdir -p /etc/supervisor/conf.d && \
    printf '[supervisord]\nnodaemon=true\n\n[program:sshd]\ncommand=/usr/sbin/sshd -D\nautorestart=true\npriority=10\n\n[program:vnc]\ncommand=/bin/sh -c "rm -f /tmp/.X1-lock /tmp/.X11-unix/X1; vncserver :1 -fg"\nautorestart=true\npriority=20\nuser=root\n' > /etc/supervisor/conf.d/services.conf

# 🔁 Supervisor config to run both VNC + SSH
RUN mkdir -p /etc/supervisor/conf.d && \
    echo '[supervisord]
nodaemon=true

[program:sshd]
command=/usr/sbin/sshd -D
autorestart=true
priority=10

[program:vnc]
command=/bin/sh -c "rm -f /tmp/.X1-lock /tmp/.X11-unix/X1; vncserver :1 -fg"
autorestart=true
priority=20
user=root' > /etc/supervisor/conf.d/services.conf

EXPOSE 22 5901

# ✅ Start both services via supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/services.conf"]
