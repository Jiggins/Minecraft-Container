FROM amazonlinux

RUN yum update -y
RUN yum install -y curl iputils java-1.8.0-openjdk python3 unzip wget which
run python3 -m pip install boto3 Flask mcstatus

RUN mkdir -p /opt/minecraft
COPY lib /opt/minecraft

WORKDIR /opt/minecraft

# Extract modpack
COPY bin/unpack-server.sh /opt/minecraft/bin/unpack-server.sh
RUN /opt/minecraft/bin/unpack-server.sh

# Override modpack config files
COPY bin /opt/minecraft/bin
COPY etc /opt/minecraft

# Symlink to external volume
RUN mkdir -p /mnt/minecraft/world
RUN ln -s /mnt/minecraft/world /opt/minecraft/world

# Healthcheck port
EXPOSE 8443

# Minecraft port
EXPOSE 25565

# RCon port
EXPOSE 25575

ENTRYPOINT /opt/minecraft/bin/start-server.sh
