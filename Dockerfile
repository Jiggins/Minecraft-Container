FROM amazonlinux

RUN yum update -y
RUN yum install -y curl iputils java-1.8.0-openjdk unzip wget which

# Install a recent version of Python
RUN amazon-linux-extras enable python3.8
RUN amazon-linux-extras install python3.8
RUN ln -snf /usr/bin/python3.8 /usr/bin/python3

RUN python3 -m pip install boto3 Flask mcstatus rcon

RUN mkdir -p /opt/minecraft
COPY lib /opt/minecraft

WORKDIR /opt/minecraft

# Extract modpack
COPY bin/unpack-server.sh /opt/minecraft/bin/unpack-server.sh
RUN /opt/minecraft/bin/unpack-server.sh

# Override modpack config files
COPY bin /opt/minecraft/bin
COPY etc /opt/minecraft

# Healthcheck port
EXPOSE 8443

# Minecraft port
EXPOSE 25565

# RCon port
EXPOSE 25575

ENTRYPOINT /opt/minecraft/bin/start-server.sh
