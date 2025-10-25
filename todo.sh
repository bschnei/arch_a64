#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

. "$(dirname "$(readlink -e "$0")")/functions"

repos=("core" "extra")
readonly repos

rm -f todo.update todo.remove todo.ahead

for repo in "${repos[@]}"; do

  echo "Generating todo lists for [${repo}]..."
  extract_state "${script_dir}/pkgrepos/${repo}-staging/${repo}-staging.db.tar.gz" > "${script_dir}/state/${repo}.staged"
  extract_state "/mnt/repo/arch/${repo}/os/aarch64/${repo}.db.tar.gz" > "${script_dir}/state/${repo}.released"

  x86_64=$(< "${script_dir}/state/${repo}.x86_64")
  staged=$(< "${script_dir}/state/${repo}.staged")
  released=$(< "${script_dir}/state/${repo}.released")

  while IFS= read -r pkg; do

    pkgname=$(echo "${pkg}" | awk '{print $1}')
    pkgver=$(echo "${pkg}" | awk '{print $2}')
    staging=$(echo "${staged}" | awk -v name="${pkgname}" '$1 == name' | awk '{print $2}')

    latest=$(echo "${x86_64}" | awk -v name="${pkgname}" '$1 == name' | awk '{print $2}')
    pkgbase=$(echo "${x86_64}" | awk -v name="${pkgname}" '$1 == name' | awk '{print $3}')
    pkgarch=$(echo "${x86_64}" | awk -v name="${pkgname}" '$1 == name' | awk '{print $4}')

    if [ -z $latest ]; then
      echo "${repo} ${pkgname}" >> todo.remove
      continue
    fi

    state=$(vercmp ${latest} ${pkgver})
    if [ $state -gt 0 ]; then
      if [[ "${staging}" == "${latest}" ]]; then
        echo "  ${pkgname} ${staging} is staged"
      else
        echo "  ${pkgname} ${pkgver} => ${latest}"
        echo "${pkgname} ${latest} ${repo} ${pkgbase} ${pkgarch}" >> todo.update
      fi
    elif [ $state -lt 0 ]; then
      echo "${pkgname} ${pkgver} > ${latest}" >> todo.ahead
    fi

  done <<< "${released}"

done
