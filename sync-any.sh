#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

pkgrepo_path="${script_dir}/pkgrepos"
readonly pkgrepo_path

# for each repo
repos=("core" "extra")
for repo in "${repos[@]}"; do

  readarray -t pkgfiles < <(rsync \
    --itemize-changes \
    --copy-links \
    --times \
    --exclude=aarch64-linux-gnu-* \
    --exclude=amd-ucode* \
    --exclude=intel-ucode* \
    --exclude=sigrok-firmware-fx2lafw-* \
    "rsync://berlin.mirror.pkgbuild.com/packages/${repo}/os/x86_64/*-any.pkg.tar.*" "${pkgrepo_path}/${repo}/" | awk '{print $2}' | grep -v '\.sig$')
 
  if [ ${#pkgfiles[@]} -eq 0 ]; then continue; fi

  pkglist=$(printf "${pkgrepo_path}/${repo}/%s " "${pkgfiles[@]}")
  repo-add --remove -p "${pkgrepo_path}/${repo}/${repo}.db.tar.zst" ${pkglist[@]}

done
