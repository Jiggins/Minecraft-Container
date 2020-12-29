FROM amazonlinux

# RUN pacman --noconfirm -Syyuu curl unzip wget which
RUN yum install -y curl iputils java-1.8.0-openjdk nmap-netcat python3 unzip wget which
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

EXPOSE 8443
EXPOSE 25565
ENTRYPOINT /opt/minecraft/bin/start-server.sh
