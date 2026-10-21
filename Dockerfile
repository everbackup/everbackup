FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV GOTOOLCHAIN=auto

LABEL org.opencontainers.image.source="https://github.com/everbackup/everbackup"


RUN apt update && \ 
    apt install -y curl && \
    apt install -y openssh-server sudo bash nano && \
    apt-get install -y supervisor && \
    mkdir -p /var/log/supervisor && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash everbackup && \
    echo "everbackup:default" | chpasswd && \
    usermod -aG sudo everbackup && \
    echo "everbackup ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


RUN mkdir -p /usr/local/bin/hotpocket

COPY hotpocket/hpcore /usr/local/bin/hotpocket/hpcore
COPY hotpocket/hpfs /usr/local/bin/hotpocket/hpfs
COPY hotpocket/hpws /usr/local/bin/hotpocket/hpws
COPY hotpocket/evernode-license.pdf /usr/local/bin/hotpocket/

RUN chmod +x /usr/local/bin/hotpocket/*

COPY lib/libblake3.so /usr/local/lib/
COPY lib/libssl.so.1.1 /usr/lib/x86_64-linux-gnu/
COPY lib/libcrypto.so.1.1 /usr/lib/x86_64-linux-gnu/

RUN ldconfig && mkdir -p /contract

RUN mkdir /var/run/sshd && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "ListenAddress 0.0.0.0" >> /etc/ssh/sshd_config

COPY start.sh /start.sh
COPY supervisord.conf /home/everbackup/supervisord.conf


RUN chmod +x /start.sh


WORKDIR /home/everbackup
ENTRYPOINT ["/start.sh"]
