#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

. "$(dirname "$(readlink -e "$0")")/functions"

pkgrepo_path="${script_dir}/pkgrepos"
state_path="${script_dir}/state"
readonly pkgrepo_path state_path

# load packages to be removed from todo list
remove=$(awk '$1 == "remove" {print $2,$3}' "${state_path}/todo")

while IFS= read -r line; do

  if [ -z "${line}" ]; then continue; fi
  pkgname=$(echo "${line}" | cut -d ' ' -f 1)
  pkgrepo=$(echo "${line}" | cut -d ' ' -f 2)

  bash "${script_dir}/remove.sh" "${pkgname}" "${pkgrepo}"

done <<< "${remove}"


# load packages to be synced from todo list
sync=$(awk '$1 == "sync" {print $2,$3,$4}' "${state_path}/todo")

while IFS= read -r line; do

  if [ -z "${line}" ]; then continue; fi
  pkgname=$(echo "${line}" | cut -d ' ' -f 1)
  pkgver=$(echo "${line}" | cut -d ' ' -f 2)
  pkgrepo=$(echo "${line}" | cut -d ' ' -f 3)

  rsync -Lavh "rsync://berlin.mirror.pkgbuild.com/packages/${pkgrepo}/os/x86_64/${pkgname}-${pkgver}-any.pkg.tar.*" "${pkgrepo_path}/${pkgrepo}-staging/"
  repo-add --remove "${pkgrepo_path}/${pkgrepo}-staging/${pkgrepo}-staging.db.tar.gz" "${pkgrepo_path}/${pkgrepo}-staging/${pkgname}-${pkgver}-any.pkg.tar.zst"

done <<< "${sync}"


# load packages to be built from todo list
build=$(awk '$1 == "build" {print $2,$3,$4}' "${state_path}/todo")

# deduplicate pkgbases
pkgbases=()
pkgvers=()
while IFS= read -r line; do

  if [ -z "${line}" ]; then continue; fi
  pkgname=$(echo "${line}" | cut -d ' ' -f 1)
  pkgver=$(echo "${line}" | cut -d ' ' -f 2)
  pkgbase=$(get_pkgbase "${pkgname}")

  # ignore pkgbase already in the list
  if printf '%s\n' "${pkgbases[@]}" | grep -xq "${pkgbase}"; then
    continue
  fi

  pkgbases+=("${pkgbase}")
  pkgvers+=("${pkgver}")

done <<< "${build}"

for (( i=0; i<${#pkgbases[@]}; i++ )); do

  # TODO: handle "special" packages
  bash "${script_dir}/stage.sh" "${pkgbases[i]}" "${pkgvers[i]}"

done

