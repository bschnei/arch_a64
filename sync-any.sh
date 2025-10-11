#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

# stage arch='any' packages and signatures from x86_64 mirrors

repos=("core" "extra")
readonly repos

for repo in "${repos[@]}"; do

  # path to aarch64 staging repo
  pkgrepo_path="${script_dir}/pkgrepos/${repo}-staging"

  # use --dry-run to geta list files that will be changed
  # TODO: this will not work right if there are "deletes" in the rsync output!!
  filelist=$(rsync -Lav --delete --dry-run --exclude aarch64-* "rsync://mirror.pkgbuild.com/packages/${repo}/os/x86_64/*-any.pkg.tar.zst" "${pkgrepo_path}/" | head -n -3 | tail -n +2)

  # do the actual sync
  rsync -Lavh --delete --exclude aarch64-* "rsync://mirror.pkgbuild.com/packages/${repo}/os/x86_64/*-any.pkg.tar.*" "${pkgrepo_path}/"

  # add the packages that were updated to the repo database
  for file in ${filelist}; do
    repo-add --remove "${pkgrepo_path}/${repo}-staging.db.tar.gz" "${pkgrepo_path}/${file}"
  done
  
done

