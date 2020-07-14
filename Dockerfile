FROM amazonlinux

# RUN pacman --noconfirm -Syyuu curl unzip wget which
RUN yum install -y curl iputils java-1.8.0-openjdk unzip wget which

RUN mkdir -p /opt/minecraft
COPY lib /opt/minecraft
COPY bin /opt/minecraft/bin

# Extract modpack
RUN /opt/minecraft/bin/unpack-server.sh

# Override modpack config files
COPY etc /opt/minecraft

RUN chmod +x /opt/minecraft/server-start.sh

WORKDIR /opt/minecraft
RUN bash -x /opt/minecraft/server-start.sh

# Agree to the EULA
RUN sed -i '/^eula/s/false/true/' eula.txt

EXPOSE 25565
ENTRYPOINT /opt/minecraft/server-start.sh
