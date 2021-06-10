#!/bin/bash

set -eu

function die() {
  local ret=$?
  echo "${*}"
  exit ${ret}
}

zipfile=$(find /opt/minecraft -maxdepth 1 -type f -name '*.zip')

installer=$(find /opt/minecraft -maxdepth 1 -type f -name 'serverinstall_*')

function install_from_zip() {
  echo "Exrtacting ${zipfile}"
  unzip "${zipfile}" \
    || die "Failed to extract ${zipfile}"

  rm -v "${zipfile}"

  echo "Successfully extracted ${zipfile}"
}

# FTB distributes a binary file to install mods intead of a script or a zip
# file. This is a terrible idea from a security perspective but at least we're
# running in Docker. Arbitrary code execution as a service.
function install_from_binary() {
  chmod +x "${installer}"
  "${installer}"
}

pushd /opt/minecraft

if [[ -n "${zipfile}" ]]; then
  install_from_zip \
    || die "Failed to unpack and install ${zipfile}"
  exit $?
fi

if [[ -n "${installer}" ]]; then
  install_from_binary \
    || die "Failed to install from binary installer: ${installer}"

  exit $?
fi

die "No modpack found, exiting"
