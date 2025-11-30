#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

. "$(dirname "$(readlink -e "$0")")/functions"

state_path="${script_dir}/state"
readonly state_path

# remove any old tobuild list
rm -f "${script_dir}/pkglist/tobuild"

echo "Looking for outdated packages..."

pkgbases=()
pkgvers=()

repos=("core" "extra")
for repo in "${repos[@]}"; do

  # load the state of the repos from disk
  upstream=$(< "${state_path}/${repo}")
  staged=$(tar -tvzf "${script_dir}/pkgrepos/${repo}-staging/${repo}-staging.db.tar.gz" | grep -e "^d" | awk '{print $6}' | sed 's/.$//')
  released=$(tar -tvzf "${script_dir}/pkgrepos/${repo}/${repo}.db.tar.gz" | grep -e "^d" | awk '{print $6}' | sed 's/.$//')

  # for each package in ${released}...
  while IFS= read -r pkg; do

    # each line in ${released} is formatted as: pkgname-pkgver
    # e.g. linux-6.16.7-arch1
    pkgname=$(echo "${pkg}" | sed -E 's/-[^-]+-[^-]+$//')

    # + is a special character for regex that can be in pkgname
    # so escape it when parsing out pkgver
    pattern=$(echo "${pkgname}" | sed 's/+/\\+/g')
    pkgver_released=$(echo "${pkg}" | sed -E "s/^${pattern}-//")

    # pkgver in ${repo}-staged
    pkgver_staged=$(echo "${staged}" | grep -E -m 1 "^${pattern}-[^-]+-[^-]+$" | sed -E "s/^${pattern}-//")

    # pkgver from upstream
    pkgver_upstream=$(echo "${upstream}" | awk -v name="${pkgname}" '$1 == name' | awk '{print $2}')
    pkgarch=$(echo "${upstream}" | awk -v name="${pkgname}" '$1 == name' | awk '{print $4}')

    # skip 'any' packages
    if [[ "${pkgarch}" == "any" ]]; then continue; fi

    # compare upstream with what is released
    state=$(vercmp "${pkgver_upstream}" "${pkgver_released}")
    
    # if up-to-date, there is nothing to do
    if [[ "${state}" == "0" ]]; then continue; fi

    # if the latest upstream version is already in staging, it is pending release
    if [[ "${pkgver_staged}" == "${pkgver_upstream}" ]]; then continue; fi

    # if behind the x86_64 version, we need to build it
    if [ "${state}" -gt 0 ]; then
      echo "${pkgname} ${pkgver_upstream}" >> "${script_dir}/pkglist/tobuild"
      continue
    fi

    # if we made it this far we have a pkgver newer than upstream
    #echo "  I ${pkgname} ${pkgver_released} ahead of upstream (${pkgver_upstream})"

  done <<< "${released}"

done

