FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install basic tools
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    ca-certificates curl dialog gpg nano netcat-openbsd net-tools wget git less locales \
    lsb-release libtool-bin ssl-cert sngrep sudo systemd systemd-sysv unzip \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
RUN locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Add FusionPBX install script
RUN git clone --depth 1 https://github.com/fusionpbx/fusionpbx-install.sh.git /usr/src/fusionpbx-install.sh 
COPY install.sh /usr/src/fusionpbx-install.sh/debian/docker-install.sh
COPY postgresql.sh /usr/src/fusionpbx-install.sh/debian/resources/docker-postgresql.sh
COPY setup.sh /usr/src/fusionpbx-install.sh/debian/resources/setup.sh
RUN chmod +x /usr/src/fusionpbx-install.sh/debian/install.sh /usr/src/fusionpbx-install.sh/debian/resources/setup.sh /usr/src/fusionpbx-install.sh/debian/resources/docker-postgresql.sh

# Run the modified install script (Debian Docker)
RUN bash /usr/src/fusionpbx-install.sh/debian/docker-install.sh \
    && apt-get purge -y \
    build-essential \
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
    *-dev \
    && apt-get install libspeex1 libspeexdsp1 \
    && apt-get autoremove -y --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf \
    /usr/share/doc/* \
    /usr/share/man/* \
    /usr/src/freeswitch* \
    /usr/src/sofia* \
    /usr/src/libks \
    /usr/src/spandsp \
    /usr/src/*.zip

# Volumes
VOLUME ["/var/lib/freeswitch", "/etc/freeswitch", "/etc/nginx", "/var/log/freeswitch", "/var/www/fusionpbx", "/var/lib/postgresql/data" ]

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/freeswitch", "-nf"]
