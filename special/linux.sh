#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

chroot_path="${script_dir}/../chroot"
srcrepos_path="${script_dir}/../srcrepos"
pkgrepos_path=$(realpath "${script_dir}/../pkgrepos")
readonly chroot_path srcrepos_path pkgrepos_path 

pkgname=linux
readonly pkgname

upstream_url="git@gitlab.archlinux.org:archlinux/packaging/packages/${pkgname}.git"

cd "${srcrepos_path}" || exit
rm -rf -- "${pkgname}"
git clone "git@gitlab.archlinux.org:bschnei/${pkgname}.git"
cd "${pkgname}" || exit

git remote add upstream "${upstream_url}"
git fetch --all --tags
git merge upstream/main
git push
git push --tags
git checkout aarch64
git rebase -X ours main aarch64
updpkgsums

if ! makechrootpkg -r "${chroot_path}" -D "${pkgrepos_path}/core-staging" -D "${pkgrepos_path}/extra-staging" -c -- --nobuild; then exit; fi

latest=$(ls linux-*.tar.xz | sed 's/linux-//' | sed 's/.tar.xz//')

cp -- "${chroot_path}/ben/build/${pkgname}/src/linux-${latest}/.config" config.aarch64
updpkgsums
git commit --all --amend --no-edit
if ! makechrootpkg -r "${chroot_path}" -D "${pkgrepos_path}/core-staging" -D "${pkgrepos_path}/extra-staging"; then exit; fi
git push --force

# add to staging package repo
for pkg in *.pkg.tar.*; do
  mv "${pkg}" "${pkgrepos_path}/core-staging"
  repo-add --remove "${pkgrepos_path}/core-staging/core-staging.db.tar.zst" "${pkgrepos_path}/core-staging/${pkg}"
done

# remove build artifacts
cd "${srcrepos_path}" || exit
rm -rf -- "${pkgname}"

