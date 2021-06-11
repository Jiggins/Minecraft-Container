#!/bin/bash

set -eux

account_id=$(aws sts get-caller-identity | jq -r .Account)

declare registry=${account_id}.dkr.ecr.eu-west-1.amazonaws.com
declare docker_tag="${registry}/minecraft"

docker build --tag "${docker_tag}" .

function interactive() {
  docker run -it --rm \
    -p 8443:8443 \
    -p 25565:25565 \
    -p 25575:25575 \
    --volume minecraft:/mnt/minecraft \
    "${docker_tag}:latest"
}

function background() {
  container=$(docker run \
    --rm \
    --detach \
    -p 8443:8443 \
    -p 25565:25565 \
    -p 25575:25575 \
    --volume minecraft:/mnt/minecraft \
    "${docker_tag}:latest")

  trap "docker stop ${container}"  EXIT

  docker exec -it "${container}" bash --login
}

function push() {
  aws ecr get-login-password --region eu-west-1 \
    | docker login --username AWS --password-stdin "${registry}"

  docker push "${docker_tag}"
}

while (( $# > 0 )); do
  case "${1}" in
    -i|--interactive)
      interactive
      ;;

    -b|--background)
      background
      ;;

    -p|--push)
      push
      ;;
  esac

  shift
done
