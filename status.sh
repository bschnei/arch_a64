#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

core=$(curl -s https://ziply.mm.fcix.net/archlinux/core/os/x86_64/core.db.tar.gz | tar -tvz | grep -e "^d" | awk '{print $6}' | sed 's/.$//')
extra=$(curl -s https://ziply.mm.fcix.net/archlinux/extra/os/x86_64/extra.db.tar.gz | tar -tvz | grep -e "^d" | awk '{print $6}' | sed 's/.$//')
stable=$(echo "${core} ${extra}" | tr " " "\n" | sort)
 
testing=$(curl -s https://repo.bens.haus/arch/testing/os/aarch64/testing.db.tar.gz | tar -tvz | grep -e "^d" | awk '{print $6}' | sed 's/.$//')

rm -f pkglist.update pkglist.remove

for line in ${testing}; do

  pkgname=$(echo ${line} | sed -E 's/-[^-]+-[^-]+$//')
  pkgver=$(echo ${line} | sed -E "s/^${pkgname}-//")
  latest=$(echo ${stable} | tr " " "\n" | grep -E -m 1 "^${pkgname}-[^-]+-[^-]+$" | sed -E "s/^${pkgname}-//")

  if [ -z $latest ]; then
    if [ "${pkgname}" = "linux-a3700" ]; then continue; fi
    echo "${pkgname}" >> pkglist.remove
    continue
  fi

  state=$(vercmp ${latest} ${pkgver})
  if [ $state -gt 0 ]; then
    echo "${pkgname} ${pkgver} => ${latest}"
    echo "${pkgname} ${latest}" >> pkglist.update
#  elif [ $state -lt 0 ]; then
#    echo "${pkgname} is ${pkgver} which is newer than upstream!? ${latest}"
  fi

done
