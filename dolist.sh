#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

list_name="${1}"

if [ ! -f "${script_dir}/pkglist.${list_name}" ]; then exit; fi

echo "Packages to stage:"
cat "${script_dir}/pkglist.${list_name}"

# array of PKGBUILD repos and tags we want to build
pkgrepos=()
pkgrefs=()

# for each package on the list...
while IFS= read -r line; do

  pkgname=$(echo ${line} | awk '{print $1}')

  # map a package name to its base package
  pkgbase=$(pacman -Sdd "${pkgname}" --print-format %e 2>/dev/null)

  # if a package is not in the database, just use its name
  if [ -z "${pkgbase}" ]; then pkgbase=${pkgname}; fi

  # ignore package already in the list
  if echo "${pkgrepos[@]}" | grep -q "${pkgbase}"; then
    continue
  fi

  pkgrepos+=("${pkgbase}")

done < <(grep -v "^#" "${script_dir}/pkglist.${list_name}" | grep -v "^$")

# for each PKGBUILD repo that we want to build
for (( i=0; i<${#pkgrepos[@]}; i++ )); do

  repo=${pkgrepos[i]}

  bash "${script_dir}/stage.sh" "${repo}"

done
