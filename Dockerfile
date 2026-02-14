FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install basic tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo curl wget git lsb-release gnupg unzip \
    netcat-openbsd ssl-cert ca-certificates locales \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Add FusionPBX install script
RUN git clone --depth 1 https://github.com/fusionpbx/fusionpbx-install.sh.git /usr/src/fusionpbx-install.sh 

# Run the official install script (Debian)
RUN bash /usr/src/fusionpbx-install.sh/debian/install.sh \
    && apt-get purge -y \
    build-essential \
    fail2ban \
    autoconf \
    automake \
    libtool \
    pkg-config \
    cmake \
    yasm \
    wget \
    curl \
    gnupg \
    unzip \
    lsb-release \
    *-dev \
    && apt-get autoremove -y --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf \
    /usr/share/doc/* \
    /usr/share/man/* \
    /usr/share/locale/* \
    /usr/src/freeswitch* \
    /usr/src/sofia* \
    /usr/src/libks \
    /usr/src/spandsp \
    /usr/src/*.zip

# Volumes
VOLUME ["/var/lib/freeswitch", "/etc/freeswitch", "/var/log/freeswitch", "/var/www/fusionpbx"]

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/freeswitch", "-nf"]
