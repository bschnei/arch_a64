#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

chroot_path="${script_dir}/chroot"
srcrepos_path="${script_dir}/srcrepos"
pkgrepos_path="${script_dir}/pkgrepos"
readonly chroot_path srcrepos_path pkgrepos_path 

gitname="${1}"
gitref="${2-main}"

upstream_url="git@gitlab.archlinux.org:archlinux/packaging/packages/${gitname}.git"
fork_url="git@gitlab.archlinux.org:bschnei/${gitname}.git"
readonly upstream_url fork_url

cd "${srcrepos_path}" || exit
rm -rf -- "${gitname}"

# if a fork of this package exists...
if git ls-remote --quiet "${fork_url}" > /dev/null 2>&1; then
  git clone "${fork_url}"
  cd "${gitname}" || exit
  
  git remote add upstream "${upstream_url}"
  git fetch --all --tags
  git merge upstream/main
  git push
  git checkout aarch64
  if ! git rebase main aarch64; then exit; fi
else
  git clone "${upstream_url}"
  cd "${gitname}" || exit
  
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

# import any signing keys
gpg --quiet --import keys/pgp/*.asc > /dev/null 2>&1

# https://gitlab.archlinux.org/archlinux/packaging/packages/gawk/-/issues/2#note_255035
SOURCE_DATE_EPOCH=$(date +%s)
export SOURCE_DATE_EPOCH

if ! makechrootpkg -r "${chroot_path}" -D "${pkgrepos_path}/staging" -c -- --ignorearch; then exit; fi

# add to staging package repo
for pkg in *.pkg.tar.*; do
  mv "${pkg}" "${pkgrepos_path}/staging"
  repo-add --remove "${pkgrepos_path}/staging/staging.db.tar.gz" "${pkgrepos_path}/staging/${pkg}"
done

# remove build artifacts
cd "${srcrepos_path}" || exit
rm -rf -- "${gitname}"

