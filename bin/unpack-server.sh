#!/bin/bash

set -eu

function die() {
  local ret=$?
  echo "${*}"
  exit ${ret}
}

zipfile=$(find /opt/minecraft -type f -name '*.zip')

pushd /opt/minecraft

echo "Exrtacting ${zipfile}"
unzip "${zipfile}" \
  || die "Failed to extract ${zipfile}"

rm -v "${zipfile}"

echo "Successfully extracted ${zipfile}"
