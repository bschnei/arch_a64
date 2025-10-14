#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

# update local state files

rm -rf -- "${script_dir}/state"
mkdir "${script_dir}/state"
cd state || exit

repos=("core" "extra")
readonly repos

for repo in "${repos[@]}"; do

  echo "Processing [${repo}] database..."
  rm -rf -- "${repo}"

  mkdir "${repo}"
  curl -s "https://berlin.mirror.pkgbuild.com/${repo}/os/x86_64/${repo}.db.tar.gz" | tar --extract --gzip --directory="${repo}"

  for pkg in "${repo}"/*/desc; do

    pkgname=$(awk '/%NAME%/{getline; print}' "${pkg}")
    pkgbase=$(awk '/%BASE%/{getline; print}' "${pkg}")
    pkgver=$(awk '/%VERSION%/{getline; print}' "${pkg}")
    pkgarch=$(awk '/%ARCH%/{getline; print}' "${pkg}")

    echo "${pkgname} ${pkgver} ${repo} ${pkgbase} ${pkgarch}" >> x86_64

  done
  rm -rf -- "${repo}"

  mkdir "${repo}"
  tar --extract --gzip --directory="${repo}" -f ${script_dir}/pkgrepos/${repo}-staging/${repo}-staging.db.tar.gz

  for pkg in "${repo}"/*/desc; do

    pkgname=$(awk '/%NAME%/{getline; print}' "${pkg}")
    pkgbase=$(awk '/%BASE%/{getline; print}' "${pkg}")
    pkgver=$(awk '/%VERSION%/{getline; print}' "${pkg}")
    pkgarch=$(awk '/%ARCH%/{getline; print}' "${pkg}")

    echo "${pkgname} ${pkgver} ${repo} ${pkgbase} ${pkgarch}" >> staged

  done
  rm -rf -- "${repo}"

  mkdir "${repo}"
  tar --extract --gzip --directory="${repo}" -f ${script_dir}/pkgrepos/${repo}/${repo}.db.tar.gz 

  for pkg in "${repo}"/*/desc; do

    pkgname=$(awk '/%NAME%/{getline; print}' "${pkg}")
    pkgbase=$(awk '/%BASE%/{getline; print}' "${pkg}")
    pkgver=$(awk '/%VERSION%/{getline; print}' "${pkg}")
    pkgarch=$(awk '/%ARCH%/{getline; print}' "${pkg}")

    echo "${pkgname} ${pkgver} ${repo} ${pkgbase} ${pkgarch}" >> released

  done
  rm -rf -- "${repo}"

done
