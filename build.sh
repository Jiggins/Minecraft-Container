#!/bin/bash

set -eux

account_id=$(aws sts get-caller-identity | jq -r .Account)

declare registry=${account_id}.dkr.ecr.eu-west-1.amazonaws.com
declare docker_tag="${registry}/minecraft"

docker build --tag "${docker_tag}" .

# docker run -p 8443:8443 -p 25565:25565 --expose 25565 "${docker_tag}:latest"

aws ecr get-login-password --region eu-west-1 \
  | docker login --username AWS --password-stdin "${registry}"

docker push "${docker_tag}"
