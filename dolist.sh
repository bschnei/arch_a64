#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

. "$(dirname "$(readlink -e "$0")")/functions"

list="${1}"

while IFS= read -r pkgname; do

  pkgrepo=$(get_repo "${pkgname}")
  if [ -z "${pkgrepo}" ]; then echo "Could not determine repo for ${pkgname}!"; exit; fi

  pkginfo=$(awk -v name="${pkgname}" '$1 == name' "${script_dir}/state/${pkgrepo}")
  if [ -z "${pkginfo}" ]; then echo "${pkgname} not found in state/${pkgrepo}!"; exit; fi

  pkgver=$(echo "${pkginfo}" | cut -d ' ' -f 2)
  pkgbase=$(echo "${pkginfo}" | cut -d ' ' -f 3)
  pkgarch=$(echo "${pkginfo}" | cut -d ' ' -f 4)

  bash "${script_dir}/stage.sh" "${pkgname}" "${pkgver}" "${pkgrepo}" "${pkgbase}" "${pkgarch}"

done < <(grep -v "^#" "${script_dir}/pkglist.${list}" | grep -v "^$")

