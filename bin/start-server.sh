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

java "${JVM_ARGS[@]}" -jar "${forge_jar}" nogui
