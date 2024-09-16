#!/usr/bin/env bash
set -e

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

pkgname=linux-a3700
readonly pkgname

# get latest stable release version
latest=$(curl -s https://www.kernel.org/releases.json | jq -r '.releases.[1].version')
readonly latest

# get latest package version
cd "${script_dir}/repos" || exit
if [ -d "${pkgname}" ]; then
  cd "${pkgname}" || exit
  git pull --quiet
else
  git clone git@github.com:bschnei/${pkgname}.git
  cd "${pkgname}" || exit
fi

current=$(sed -n -e 's/^pkgver=//p' PKGBUILD)
readonly current

# quit if the two versions are the same
if [ "${latest}" = "${current}" ]; then
  echo "${pkgname} is up-to-date (${current})"
  exit 0
fi

# get the new hash from upstream
new_sha256sum=$(curl -L "https://www.kernel.org/pub/linux/kernel/v${latest%%.*}.x/sha256sums.asc" | sed -n -e "s/  linux-${latest}.tar.xz$//p")
readonly new_sha256sum

# modify the PKGBUILD
sed -i "s|^pkgver=.*$|pkgver=${latest}|g" PKGBUILD
sed -i "s|^pkgrel=.*$|pkgrel=1|g" PKGBUILD
sed -i "s|^sha256sums=(.*$|sha256sums=('${new_sha256sum}'|g" PKGBUILD

# clean build the new package
makepkg --force --cleanbuild --syncdeps --rmdeps --noconfirm

# add updated config to the package
cp "src/linux-${latest}/.config" config

# update the SHA256 sums
updpkgsums

# version control changes
git commit --all --message="${latest}-1"
git tag "${latest}-1"
git push
git push --tags

# move package to repo server and clean unversioned files
mv "${pkgname}-${latest}-1-aarch64.pkg.tar.xz" "${script_dir}/pkg"
git clean -d --force

# update package repository database
cd "${script_dir}/pkg" || exit
repo-add rocky.db.tar.xz "${pkgname}-${latest}-1-aarch64.pkg.tar.xz"

