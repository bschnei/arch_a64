#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

. "$(dirname "$(readlink -e "$0")")/functions"

chroot_path="${script_dir}/chroot"
srcrepos_path="${script_dir}/srcrepos"
pkgrepos_path="${script_dir}/pkgrepos"
state_path="${script_dir}/state"
readonly chroot_path srcrepos_path pkgrepos_path state_path

pkgname="${1}"

if [ -n "${2}" ]; then
  pkgver="${2}"
else
  pkgver=$(get_pkgver "${pkgname}")
fi

pkgrepo=$(get_pkgrepo "${pkgname}")
pkgrepo_path="${pkgrepos_path}/${pkgrepo}-staging"
readonly pkgrepo pkgrepo_path

pkgarch=$(get_pkgarch "${pkgname}")
readonly pkgarch

# arch=(any) packages we can just copy from upstream
if [ "${pkgarch}" == "any" ]; then

  rsync -Lavh "rsync://berlin.mirror.pkgbuild.com/packages/${pkgrepo}/os/x86_64/${pkgname}-${pkgver}-any.pkg.tar.*" "${pkgrepo_path}/"
  repo-add --remove "${pkgrepo_path}/${pkgrepo}-staging.db.tar.gz" "${pkgrepo_path}/${pkgname}-${pkgver}-any.pkg.tar.zst"
  exit

fi

# if arch isn't 'any' then we have to build the package...
pkgbase=$(get_pkgbase "${pkgname}")
readonly pkgbase

upstream_url="git@gitlab.archlinux.org:archlinux/packaging/packages/${pkgbase}.git"
fork_url="git@gitlab.archlinux.org:bschnei/${pkgbase}.git"
readonly upstream_url fork_url

cd "${srcrepos_path}" || exit
rm -rf -- "${pkgbase}"

# if a fork of this package exists...
if git ls-remote --quiet "${fork_url}" > /dev/null 2>&1; then
  git clone "${fork_url}"
  cd "${pkgbase}" || exit

  git remote add upstream "${upstream_url}"
  git fetch --all --tags
  git merge upstream/main
  git push
  git push --tags
  git checkout aarch64
  if ! git rebase main aarch64; then exit; fi
  git push --force
else
  git clone "${upstream_url}"
  cd "${pkgbase}" || exit

  # default to HEAD of main if no pkgver was specified
  if [ -z "${pkgver}" ]; then
    gitref="main"
  else
    gitref=$(echo "${pkgver}" | tr ":" "-")
  fi

  # for each commit made after $gitref...
  for commit in $(git rev-list --reverse ${gitref}..); do
    # if it has a tag, stop
    if git describe --exact-match "${commit}"; then break;
    else
      # otherwise advance gitref so we include all commits up
      # until the next release tag
      gitref="${commit}"
    fi
  done

  git -c advice.detachedHead=false checkout "${gitref}"
fi

# update the root chroot
arch-nspawn "${chroot_path}/root" pacman -Syu --noconfirm

# import any signing keys
gpg --quiet --import keys/pgp/*.asc > /dev/null 2>&1

# https://gitlab.archlinux.org/archlinux/packaging/packages/gawk/-/issues/2#note_255035
SOURCE_DATE_EPOCH=$(date +%s)
export SOURCE_DATE_EPOCH

# build
if ! makechrootpkg -r "${chroot_path}" -D "${pkgrepos_path}/core-staging" -D "${pkgrepos_path}/extra-staging" -c -- --ignorearch; then exit; fi

# add built packages to staging repo
for pkg in *.pkg.tar.*; do
  mv "${pkg}" "${pkgrepo_path}"
  repo-add --remove "${pkgrepo_path}/${pkgrepo}-staging.db.tar.gz" "${pkgrepo_path}/${pkg}"
done

# remove from tobuild list 
pattern=$(echo "${pkgname}" | sed 's/+/\\+/g')
sed -i "/^${pattern} ${pkgver} ${pkgrepo}$/d" "${state_path}/tobuild"

# remove build artifacts
cd .. || exit
rm -rf -- "${pkgbase}"

