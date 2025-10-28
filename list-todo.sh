#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

repos=("core" "extra")
readonly repos

true > to.stage
true > to.unstage

for repo in "${repos[@]}"; do

  echo "Generating todo lists for [${repo}]..."

  x86_64=$(< "${script_dir}/state/${repo}")
  staged=$(tar -tvzf "${script_dir}/pkgrepos/${repo}-staging/${repo}-staging.db.tar.gz" | grep -e "^d" | awk '{print $6}' | sed 's/.$//')
  released=$(tar -tvzf "${script_dir}/pkgrepos/${repo}/${repo}.db.tar.gz" | grep -e "^d" | awk '{print $6}' | sed 's/.$//')

  while IFS= read -r pkg; do

    pkgname=$(echo "${pkg}" | sed -E 's/-[^-]+-[^-]+$//')
    pattern=$(echo "${pkgname}" | sed 's/+/\\+/g')   
    pkgver=$(echo "${pkg}" | sed -E "s/^${pattern}-//")

    staging=$(echo "${staged}" | grep -E -m 1 "^${pattern}-[^-]+-[^-]+$" | sed -E "s/^${pattern}-//")

    latest=$(echo "${x86_64}" | awk -v name="${pkgname}" '$1 == name' | awk '{print $2}')
    pkgbase=$(echo "${x86_64}" | awk -v name="${pkgname}" '$1 == name' | awk '{print $3}')
    pkgarch=$(echo "${x86_64}" | awk -v name="${pkgname}" '$1 == name' | awk '{print $4}')

    # if our package is not found in the x86_64 repo, we need to remove
    if [ -z "${latest}" ]; then
      echo "  [REMOVE] ${repo}/${pkgname}"
      echo "${pkgname} ${repo}" >> to.unstage
      continue
    fi

    state=$(vercmp "${latest}" "${pkgver}")

    # if our package version is behind the x86_64 version...
    if [ "${state}" -gt 0 ]; then
      if [[ "${staging}" == "${latest}" ]]; then
        echo "  [STAGED] ${pkgname} ${staging}"
      else
        if [[ "${pkgarch}" == "any" ]]; then
          echo "  [+ SYNC] ${pkgname} ${pkgver} => ${latest}"
          echo "${pkgname}" >> to.stage
        else
          if grep -Fxq "${pkgbase}" to.stage; then continue; fi
          echo "  [+BUILD] ${pkgbase} ${pkgver} => ${latest}"
          echo "${pkgbase}" >> to.stage
        fi
      fi
    #elif [ "${state}" -lt 0 ]; then
      # our package version is ahead of x86_64
      # echo "  [IGNORE] ${pkgname} ${pkgver} ahead of upstream (${latest})"
    fi

  done <<< "${released}"

done
