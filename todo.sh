#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

x86_64=$(< "${script_dir}/state/x86_64")
staged=$(< "${script_dir}/state/staged")
released=$(< "${script_dir}/state/released")
readonly x86_64 staged released

rm -f todo.update todo.remove todo.ahead

while IFS= read -r pkg; do

  pkgname=$(echo "${pkg}" | awk '{print $1}')
  pkgver=$(echo "${pkg}" | awk '{print $2}')
  staging=$(echo "${staged}" | awk -v name="${pkgname}" '$1 == name' | awk '{print $2}')
  
  latest=$(echo "${x86_64}" | awk -v name="${pkgname}" '$1 == name' | awk '{print $2}')
  pkgrepo=$(echo "${x86_64}" | awk -v name="${pkgname}" '$1 == name' | awk '{print $3}')
  pkgbase=$(echo "${x86_64}" | awk -v name="${pkgname}" '$1 == name' | awk '{print $4}')
  pkgarch=$(echo "${x86_64}" | awk -v name="${pkgname}" '$1 == name' | awk '{print $5}')

  if [ -z $latest ]; then
    echo "${pkgrepo} ${pkgname}" >> todo.remove
    continue
  fi

  state=$(vercmp ${latest} ${pkgver})
  if [ $state -gt 0 ]; then
    if [[ "${staging}" == "${latest}" ]]; then
      echo "  ${pkgname} ${staging} is staged"
    else
      echo "  ${pkgname} ${pkgver} => ${latest}"
      echo "${pkgname} ${latest} ${pkgrepo} ${pkgbase} ${pkgarch}" >> todo.update
    fi
  elif [ $state -lt 0 ]; then
    echo "${pkgname} ${pkgver} > ${latest}" >> todo.ahead
  fi

done <<< "${released}"
