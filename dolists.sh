#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

if [ ! -f "${script_dir}/pkglist.update" ]; then exit; fi

echo "Packages to update:"
cat "${script_dir}/pkglist.update"

if [ -f "${script_dir}/pkglist.remove" ]; then
  echo "Packages to remove:"
  cat "${script_dir}/pkglist.remove"
fi

# array of PKGBUILD repos and tags we want to build
pkgrepos=()
pkgrefs=()

# for each package on the remove list...
while IFS= read -r line; do

  pkgname=$(echo ${line} | awk '{print $1}')
  bash "${script_dir}/pkgrepos/unstage.sh" "${pkgname}"

done < <(grep -v "^#" "${script_dir}/pkglist.remove" | grep -v "^$")

# for each package on the update list...
while IFS= read -r line; do

  pkgname=$(echo ${line} | awk '{print $1}')
  pkgver=$(echo ${line} | awk '{print $2}')
  pkgref=$(echo "${pkgver}" | tr : -)

  # map a package name to its base package
  pkgbase=$(pacman -Sdd "${pkgname}" --print-format %e 2>/dev/null)

  # if a package is not in the database, just use its name
  if [ -z "${pkgbase}" ]; then pkgbase=${pkgname}; fi

  # ignore package already in the list
  if echo "${pkgrepos[@]}" | grep -q "${pkgbase}"; then
    continue
  fi

  pkgrepos+=("${pkgbase}")
  pkgrefs+=("${pkgref}")

done < <(grep -v "^#" "${script_dir}/pkglist.update" | grep -v "^$")

# for each PKGBUILD repo that we want to build
for (( i=0; i<${#pkgrepos[@]}; i++ )); do

  repo=${pkgrepos[i]}
  ref=${pkgrefs[i]}

  bash "${script_dir}/pkgrepos/stage.sh" "${repo}" "${ref}"

done
