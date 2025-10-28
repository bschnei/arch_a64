#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

repos=("core" "extra")
readonly repos

rm -f -- "${script_dir}/pkglist.missing"

for repo in "${repos[@]}"; do

  x86_64=$(< "${script_dir}/state/${repo}")
  released=$(tar -tvzf "${script_dir}/pkgrepos/${repo}/${repo}.db.tar.gz" | grep -e "^d" | awk '{print $6}' | sed 's/.$//')

  while IFS= read -r pkginfo; do

    pkgname=$(echo "${pkginfo}" | cut -d ' ' -f 1)
    pkgver=$(echo "${pkginfo}" | cut -d ' ' -f 2)
    pkgbase=$(echo "${pkginfo}" | cut -d ' ' -f 3)
    pkgarch=$(echo "${pkginfo}" | cut -d ' ' -f 4)

    if grep -Fxq "${pkgname}" pkglist.ignore; then continue; fi

    # ignore haskell- packages
    if [[ "${pkgname}" == haskell-* ]]; then continue; fi

    pattern=$(echo "${pkgname}" | sed 's/+/\\+/g')   
    latest=$(echo "${released}" | grep -E -m 1 "^${pattern}-[^-]+-[^-]+$" | sed -E "s/^${pattern}-//")

    if [ -z "${latest}" ]; then
      echo "${pkgname} ${pkgver} ${repo} ${pkgbase} ${pkgarch}" >> "${script_dir}/pkglist.missing"
    fi

  done <<< "${x86_64}"

done

