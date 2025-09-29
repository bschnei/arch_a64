#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

core_x64=$(curl -s https://ziply.mm.fcix.net/archlinux/core/os/x86_64/core.db.tar.gz | tar -tvz | grep -e "^d" | awk '{print $6}' | sed 's/.$//')
extra_x64=$(curl -s https://ziply.mm.fcix.net/archlinux/extra/os/x86_64/extra.db.tar.gz | tar -tvz | grep -e "^d" | awk '{print $6}' | sed 's/.$//')

core_a64=$(tar -tvzf ${script_dir}/pkgrepos/core/core.db.tar.gz | grep -e "^d" | awk '{print $6}' | sed 's/.$//')
extra_a64=$(tar -tvzf ${script_dir}/pkgrepos/extra/extra.db.tar.gz | grep -e "^d" | awk '{print $6}' | sed 's/.$//')
 
rm -f pkglist.update pkglist.remove pkglist.ahead

for line in ${core_a64}; do

  pkgname=$(echo ${line} | sed -E 's/-[^-]+-[^-]+$//')
  pattern=$(echo $pkgname | sed 's/+/\\+/g')   
  pkgver=$(echo ${line} | sed -E "s/^${pattern}-//")
  latest=$(echo ${core_x64} | tr " " "\n" | grep -E -m 1 "^${pattern}-[^-]+-[^-]+$" | sed -E "s/^${pattern}-//")

  if [ -z $latest ]; then
    echo "core ${pkgname}" >> pkglist.remove
    continue
  fi

  state=$(vercmp ${latest} ${pkgver})
  if [ $state -gt 0 ]; then
    echo "${pkgname} ${pkgver} => ${latest}"
    echo "core ${pkgname} ${latest}" >> pkglist.update
  elif [ $state -lt 0 ]; then
    echo "${pkgname} ${pkgver} > ${latest}" >> pkglist.ahead
  fi

done

for line in ${extra_a64}; do
  
  pkgname=$(echo ${line} | sed -E 's/-[^-]+-[^-]+$//')
  pattern=$(echo $pkgname | sed 's/+/\\+/g')   
  pkgver=$(echo ${line} | sed -E "s/^${pattern}-//")
  latest=$(echo ${extra_x64} | tr " " "\n" | grep -E -m 1 "^${pattern}-[^-]+-[^-]+$" | sed -E "s/^${pattern}-//")

  if [ -z $latest ]; then
    echo "extra ${pkgname}" >> pkglist.remove
    continue
  fi

  state=$(vercmp ${latest} ${pkgver})
  if [ $state -gt 0 ]; then
    echo "${pkgname} ${pkgver} => ${latest}"
    echo "extra ${pkgname} ${latest}" >> pkglist.update
  elif [ $state -lt 0 ]; then
    echo "${pkgname} ${pkgver} > ${latest}" >> pkglist.ahead
  fi

done

