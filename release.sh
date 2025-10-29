#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

pkgrepo_path="${script_dir}/pkgrepos"
state_path="${script_dir}/state"
readonly pkgrepo_path state_path

# load packages to be released from todo list
releases=$(awk '$1 == "release" {print $2,$3,$4}' "${state_path}/todo")

while IFS= read -r line; do

  pkgname=$(echo "${line}" | cut -d ' ' -f 1)
  pkgver=$(echo "${line}" | cut -d ' ' -f 2)
  pkgrepo=$(echo "${line}" | cut -d ' ' -f 3)

  src="${pkgrepo_path}/${pkgrepo}-staging/${pkgname}-${pkgver}-*"
  dest="${pkgrepo_path}/${pkgrepo}"

  rsync -av ${src} ${dest}/
  pkgfile="${dest}/${pkgname}-${pkgver}-*.pkg.tar.zst"
  repo-add --remove "${dest}/${pkgrepo}.db.tar.gz" ${pkgfile}

  # TODO: update state files?

done <<< "${releases}"
