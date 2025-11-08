#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

. "$(dirname "$(readlink -e "$0")")/functions"

state_path="${script_dir}/state"
readonly state_path

# load packages to be built from list
tobuild=$(< "${state_path}/tobuild")

# deduplicate pkgbases
pkgbases=()
pkgvers=()
while IFS= read -r line; do

  # skip empty lines
  if [ -z "${line}" ]; then continue; fi

  # skip commented lines
  if [[ "${line}" == "#"* ]]; then continue; fi

  pkgname=$(echo "${line}" | cut -d ' ' -f 1)
  pkgver=$(echo "${line}" | cut -d ' ' -f 2)
  pkgbase=$(get_pkgbase "${pkgname}")

  # ignore pkgbase already in the list
  if printf '%s\n' "${pkgbases[@]}" | grep -xq "${pkgbase}"; then
    continue
  fi

  pkgbases+=("${pkgbase}")
  pkgvers+=("${pkgver}")

done <<< "${tobuild}"

if [ ${#pkgbases[@]} -eq 0 ]; then
  printf "%s\n" "nothing to build!"
  exit
fi

printf "\n%s\n" "The following pkgbases will be built..."
printf "  %s\n" "${pkgbases[@]}"
read -s -n 1 -p "Press any key to continue..."
printf "\n"

for (( i=0; i<${#pkgbases[@]}; i++ )); do

  # TODO: handle "special" packages
  bash "${script_dir}/stage.sh" "${pkgbases[i]}" "${pkgvers[i]}"

done
