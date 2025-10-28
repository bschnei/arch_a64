#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

pkgname=$1
repo=$2
readonly repo pkgname

if [ -z "${pkgname}" ]; then
  echo "no package specified"
  exit
fi

repo-remove "${script_dir}/${repo}-staging/${repo}-staging.db.tar.gz" "${pkgname}"
find "${script_dir}/${repo}-staging" -type f -regextype posix-extended -regex ".*/${pkgname}-[^-]+-[^-]+-[^-]+.pkg.tar.zst" -delete
