#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

list="${1}"

while IFS= read -r pkgname; do

  pkginfo=$(awk -v name="${pkgname}" '$1 == name' "${script_dir}/state/x86_64")
  if [ -z "${pkginfo}" ]; then echo "$pkgname was not found!"; continue; fi
  pkgver=$(echo "${pkginfo}" | cut -d ' ' -f 2)
  pkgrepo=$(echo "${pkginfo}" | cut -d ' ' -f 3)
  pkgbase=$(echo "${pkginfo}" | cut -d ' ' -f 4)
  pkgarch=$(echo "${pkginfo}" | cut -d ' ' -f 5)

  bash "${script_dir}/stage.sh" "${pkgname}" "${pkgver}" "${pkgrepo}" "${pkgbase}" "${pkgarch}"

done < <(grep -v "^#" "${script_dir}/pkglist.${list}" | grep -v "^$")

