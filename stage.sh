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

cd ${srcrepos_path} || exit
rm -rf -- ${gitname}

# if a fork of this package exists...
if git ls-remote --quiet "${fork_url}" > /dev/null 2>&1; then
  git clone "${fork_url}"
  git -C "${gitname}" remote add upstream "${upstream_url}"
  git -C "${gitname}" fetch --all --tags
  git -C "${gitname}" merge upstream/main
  git -C "${gitname}" push
  git -C "${gitname}" checkout aarch64
  if ! git -C "${gitname}" rebase main aarch64; then
    echo "Rebase has to be done manually. Skipping..."
    exit
  fi
else
  GIT_TERMINAL_PROMPT=0 git clone "${upstream_url}"
fi

cd "${gitname}" || exit

# for each commit made after $gitref...
for commit in $(git rev-list --reverse "${gitref}.."); do
  # if it has a tag, stop
  if git describe --exact-match "${commit}"; then break;
  else
    # otherwise advance gitref so we include all commits up
    # until the next release tag
    gitref="${commit}"
  fi
done

git checkout "${gitref}"

# import any signing keys
gpg --quiet --import keys/pgp/*.asc > /dev/null 2>&1

# https://gitlab.archlinux.org/archlinux/packaging/packages/gawk/-/issues/2#note_255035
export SOURCE_DATE_EPOCH=$(date +%s)

if ! makechrootpkg -r "${chroot_path}" -D "${pkgrepos_path}/staging" -c -- --ignorearch; then exit; fi

# add to staging package repo
for pkg in *.pkg.tar.*; do
  mv ${pkg} "${pkgrepos_path}/staging"
  repo-add --remove "${pkgrepos_path}/staging/staging.db.tar.gz" "${pkgrepos_path}/staging/${pkg}"
done

