#!/bin/bash

set -eux

declare -a JVM_ARGS=(
  -server
  -XX:+UseG1GC
  -XX:+UnlockExperimentalVMOptions
  -Xmx7168M
  -Xms7168M
)

forge_jar=$(find /opt/minecraft -maxdepth 1 -type f -name 'forge*.jar')

if [[ ! -f "${forge_jar}" ]]; then
  echo "ERROR: Cannot find forge*.jar"
  exit 2
fi

if [[ ! -f 'eula.txt' ]]; then
  echo "eula=true" > eula.txt
fi

# Symlink to external volume
mkdir -p /mnt/minecraft/world
ln -s /mnt/minecraft/world /opt/minecraft/world

FLASK_APP=/opt/minecraft/bin/healthcheck.py flask run -h 0.0.0.0 -p 8443 &

exec java "${JVM_ARGS[@]}" -jar "${forge_jar}" nogui 2>&1
