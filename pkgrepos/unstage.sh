#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

pkgname=$1
readonly pkgname

if [ -z $pkgname ]; then
  echo "no package specified"
  exit
fi

repo-remove "${script_dir}/staging/staging.db.tar.gz" "${pkgname}"
find "${script_dir}/staging" -type f -regextype posix-extended -regex ".*/${pkgname}-[^-]+-[^-]+-[^-]+.pkg.tar.zst" -delete
