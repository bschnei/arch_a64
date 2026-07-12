#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

. "$(dirname "$(readlink -e "$0")")/functions"

pkgrepo_path="${script_dir}/pkgrepos"
readonly pkgrepo_path

pkgname="${1}"

if [ -n "${2}" ]; then
  pkgrepo="${2}"
else
  pkgrepo=$(get_pkgrepo "${pkgname}")
fi

repo-remove "${pkgrepo_path}/${pkgrepo}/${pkgrepo}.db.tar.zst" "${pkgname}"
find "${pkgrepo_path}/${pkgrepo}/" -type f -regextype posix-extended -regex ".*/${pkgname}-[^-]+-[^-]+-[^-]+.pkg.tar.zst" -delete
find "${pkgrepo_path}/${pkgrepo}/" -type f -regextype posix-extended -regex ".*/${pkgname}-[^-]+-[^-]+-[^-]+.pkg.tar.zst.sig" -delete
