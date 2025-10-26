#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

repos=("core" "extra")
readonly repos

rm -f todo.update todo.remove todo.ahead

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

    if [ -z "${latest}" ]; then
      echo "${repo} ${pkgname}" >> todo.remove
      continue
    fi

    state=$(vercmp "${latest}" "${pkgver}")
    if [ "${state}" -gt 0 ]; then
      if [[ "${staging}" == "${latest}" ]]; then
        echo "  ${pkgname} ${staging} is staged"
      else
        echo "  ${pkgname} ${pkgver} => ${latest}"
        echo "${pkgname} ${latest} ${repo} ${pkgbase} ${pkgarch}" >> todo.update
      fi
    elif [ "${state}" -lt 0 ]; then
      echo "${pkgname} ${pkgver} > ${latest}" >> todo.ahead
    fi

  done <<< "${released}"

done
