FROM ubuntu

ARG uid=1000
ARG gid=1000
ARG pw="3bwb8G/RzidNRdagX7phcM54pto="
ARG java_ver=21

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt update && \
    apt install -y \
    sudo \
    openjdk-$java_ver-jre-headless \
    openssh-server
COPY auth.conf /etc/ssh/sshd_config.d/

COPY entrypoint.sh /
RUN chmod a+x /*.sh
COPY start.sh /usr/local/bin
COPY stop.sh /usr/local/bin
RUN chmod a+x /usr/local/bin/*.sh

RUN groupadd --gid $gid minecraft && \
    useradd --uid $uid --gid $gid --password $pw --create-home --shell /bin/bash minecraft && \
    echo "minecraft:$pw" | chpasswd

COPY id-minecraft.pub /home/minecraft/.ssh/authorized_keys
RUN chown -R minecraft:minecraft /home/minecraft/.ssh && \
    chmod 700 /home/minecraft/.ssh && \
    chmod 600 /home/minecraft/.ssh/authorized_keys

EXPOSE 22/tcp \
       8123/tcp \
       19132/udp \
       19133/udp \
       25565/tcp \
       25565/udp

CMD ["/bin/bash", "-c", "/entrypoint.sh"]