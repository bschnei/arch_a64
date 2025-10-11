#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

core_x64=$(curl -s https://ziply.mm.fcix.net/archlinux/core/os/x86_64/core.db.tar.gz | tar -tvz | grep -e "^d" | awk '{print $6}' | sed 's/.$//')
extra_x64=$(curl -s https://ziply.mm.fcix.net/archlinux/extra/os/x86_64/extra.db.tar.gz | tar -tvz | grep -e "^d" | awk '{print $6}' | sed 's/.$//')

core_a64=$(tar -tvzf ${script_dir}/pkgrepos/core/core.db.tar.gz | grep -e "^d" | awk '{print $6}' | sed 's/.$//')
extra_a64=$(tar -tvzf ${script_dir}/pkgrepos/extra/extra.db.tar.gz | grep -e "^d" | awk '{print $6}' | sed 's/.$//')
 
core_staging_a64=$(tar -tvzf ${script_dir}/pkgrepos/core-staging/core-staging.db.tar.gz | grep -e "^d" | awk '{print $6}' | sed 's/.$//')
extra_staging_a64=$(tar -tvzf ${script_dir}/pkgrepos/extra-staging/extra-staging.db.tar.gz | grep -e "^d" | awk '{print $6}' | sed 's/.$//')

rm -f todo.update todo.remove todo.ahead

echo "Checking packages in [core]..."
for line in ${core_a64}; do

  pkgname=$(echo ${line} | sed -E 's/-[^-]+-[^-]+$//')
  pattern=$(echo $pkgname | sed 's/+/\\+/g')   
  pkgver=$(echo ${line} | sed -E "s/^${pattern}-//")
  latest=$(echo ${core_x64} | tr " " "\n" | grep -E -m 1 "^${pattern}-[^-]+-[^-]+$" | sed -E "s/^${pattern}-//")
  staged=$(echo ${core_staging_a64} | tr " " "\n" | grep -E -m 1 "^${pattern}-[^-]+-[^-]+$" | sed -E "s/^${pattern}-//")

  if [ -z $latest ]; then
    echo "core ${pkgname}" >> todo.remove
    continue
  fi

  state=$(vercmp ${latest} ${pkgver})
  if [ $state -gt 0 ]; then
    if [[ "${staged}" == "${latest}" ]]; then
      echo "  ${pkgname} ${staged} is staged"
    else
      echo "  ${pkgname} ${pkgver} => ${latest}"
      echo "core ${pkgname} ${latest}" >> todo.update
    fi
  elif [ $state -lt 0 ]; then
    echo "${pkgname} ${pkgver} > ${latest}" >> todo.ahead
  fi

done

echo "Checking packages in [extra]..."
for line in ${extra_a64}; do
  
  pkgname=$(echo ${line} | sed -E 's/-[^-]+-[^-]+$//')
  pattern=$(echo $pkgname | sed 's/+/\\+/g')   
  pkgver=$(echo ${line} | sed -E "s/^${pattern}-//")
  latest=$(echo ${extra_x64} | tr " " "\n" | grep -E -m 1 "^${pattern}-[^-]+-[^-]+$" | sed -E "s/^${pattern}-//")
  staged=$(echo ${extra_staging_a64} | tr " " "\n" | grep -E -m 1 "^${pattern}-[^-]+-[^-]+$" | sed -E "s/^${pattern}-//")

  if [ -z $latest ]; then
    echo "extra ${pkgname}" >> todo.remove
    continue
  fi

  state=$(vercmp ${latest} ${pkgver})
  if [ $state -gt 0 ]; then
    if [[ "${staged}" == "${latest}" ]]; then
      echo "  ${pkgname} ${staged} is staged"
    else
      echo "  ${pkgname} ${pkgver} => ${latest}"
      echo "extra ${pkgname} ${latest}" >> todo.update
    fi
  elif [ $state -lt 0 ]; then
    echo "${pkgname} ${pkgver} > ${latest}" >> todo.ahead
  fi

done

