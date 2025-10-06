#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

repo=core
pkgrepo_path="${script_dir}/${repo}-staging"
filelist=$(rsync -Lav --delete --dry-run --exclude aarch64-* "rsync://berlin.mirror.pkgbuild.com/packages/${repo}/os/x86_64/*-any.pkg.tar.zst" "${pkgrepo_path}/" | head -n -3 | tail -n +2)

rsync -Lavh --delete --exclude aarch64-* "rsync://berlin.mirror.pkgbuild.com/packages/${repo}/os/x86_64/*-any.pkg.tar.*" "${pkgrepo_path}/"
for file in ${filelist}; do
  repo-add --remove "${pkgrepo_path}/${repo}-staging.db.tar.gz" "${pkgrepo_path}/${file}"
done

repo=extra
pkgrepo_path="${script_dir}/${repo}-staging"
filelist=$(rsync -Lav --delete --dry-run --exclude aarch64-* "rsync://berlin.mirror.pkgbuild.com/packages/${repo}/os/x86_64/*-any.pkg.tar.zst" "${pkgrepo_path}/" | head -n -3 | tail -n +2)

rsync -Lavh --delete --exclude aarch64-* "rsync://berlin.mirror.pkgbuild.com/packages/${repo}/os/x86_64/*-any.pkg.tar.*" "${pkgrepo_path}/"
for file in ${filelist}; do
  repo-add --remove "${pkgrepo_path}/${repo}-staging.db.tar.gz" "${pkgrepo_path}/${file}"
done
