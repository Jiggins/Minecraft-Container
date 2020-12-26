FROM amazonlinux

# RUN pacman --noconfirm -Syyuu curl unzip wget which
RUN yum install -y curl iputils java-1.8.0-openjdk unzip wget which

RUN mkdir -p /opt/minecraft
COPY lib /opt/minecraft
COPY bin /opt/minecraft/bin

WORKDIR /opt/minecraft

# Extract modpack
RUN /opt/minecraft/bin/unpack-server.sh

# Override modpack config files
COPY etc /opt/minecraft

EXPOSE 25565
ENTRYPOINT /opt/minecraft/bin/start-server.sh
