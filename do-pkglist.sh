#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

. "$(dirname "$(readlink -e "$0")")/functions"

list="${1}"
readonly list

if [ -z "${list}" ]; then
  echo "no pkglist specified"
  exit
fi

# convert to pkgbases and ignore duplicates
pkgnames=()
pkgbases=()
while IFS= read -r pkgname; do

  pkgbase=$(get_pkgbase "${pkgname}")
  pkgarch=$(get_pkgarch "${pkgname}")

  if [ "${pkgarch}" != "any" ] && echo "${pkgbases[@]}" | grep -q "${pkgbase}"; then
    continue
  fi

  pkgnames+=("${pkgname}")
  pkgbases+=("${pkgbase}")

done < <(grep -v "^#" "${script_dir}/pkglist/${list}" | grep -v "^$")

echo "The following packages will be staged:"
printf '  %s\n' "${pkgnames[@]}"
read -s -n 1 -p "Press any key to continue..."
echo -e "\n" 

for (( i=0; i<${#pkgnames[@]}; i++ )); do

  bash "${script_dir}/stage.sh" "${pkgnames[i]}"

done

