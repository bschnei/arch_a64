#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

chroot_path="${script_dir}/../chroot"
srcrepos_path="${script_dir}/../srcrepos"
pkgrepos_path=$(realpath "${script_dir}/../pkgrepos")
readonly chroot_path srcrepos_path pkgrepos_path 

pkgname=linux-a3700
readonly pkgname

latest=$(curl -s https://www.kernel.org/releases.json | jq -r '.latest_stable.version')
current=$(pacman -Si ${pkgname} | grep -Po '^Version\s*: \K.+')
readonly latest current

if (( $(vercmp "${latest}" "${current%-*}") <= 0 )); then
  echo "${pkgname} is up-to-date (${current%-*})"
  exit 0
fi

cd "${srcrepos_path}" || exit
rm -rf -- "${pkgname}"
git clone "git@github.com:bschnei/${pkgname}.git"
cd "${pkgname}" || exit

# get the new sha256sum from upstream
new_sha256sum=$(curl -s "https://cdn.kernel.org/pub/linux/kernel/v6.x/sha256sums.asc" | grep linux-${latest}.tar.xz | awk '{print $1}')
readonly new_sha256sum

# modify the PKGBUILD
sed -i "s|^pkgver=.*$|pkgver=${latest}|g" PKGBUILD
sed -i "s|^pkgrel=.*$|pkgrel=1|g" PKGBUILD
sed -i "s|^sha256sums=(.*$|sha256sums=('${new_sha256sum}'|g" PKGBUILD

# build the new package, stopping on errors
if ! makechrootpkg -r "${chroot_path}" -D "${pkgrepos_path}/staging" -c -- --ignorearch; then exit; fi

# update config and its hash
cp -- "${chroot_path}/ben/build/${pkgname}/src/linux-${latest}/.config" config
updpkgsums

# version control changes
git commit --all --message="${latest}-1"
git push

git tag "${latest}-1"
git push --tags

# add to staging package repo
for pkg in *.pkg.tar.*; do
  mv "${pkg}" "${pkgrepos_path}/staging"
  repo-add --remove "${pkgrepos_path}/staging/staging.db.tar.gz" "${pkgrepos_path}/staging/${pkg}"
done

# remove build artifacts
cd "${srcrepos_path}" || exit
rm -rf -- "${pkgname}"

