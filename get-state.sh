#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

# update local state files

rm -rf -- "${script_dir}/state"
mkdir "${script_dir}/state"
cd state || exit

repos=("core" "extra")
readonly repos

extract_state () {

  for pkg in "${1}"/*/desc; do

    # TODO: load file to memory once should improve performance
    #pkgdesc=$(cat "${pkg}")

    pkgname=$(awk '/%NAME%/{getline; print}' "${pkg}")
    pkgbase=$(awk '/%BASE%/{getline; print}' "${pkg}")
    pkgver=$(awk '/%VERSION%/{getline; print}' "${pkg}")
    pkgarch=$(awk '/%ARCH%/{getline; print}' "${pkg}")

    echo "${pkgname} ${pkgver} ${repo} ${pkgbase} ${pkgarch}"

  done

}

for repo in "${repos[@]}"; do

  echo "Processing [${repo}] database..."
  rm -rf -- "${repo}"

  mkdir "${repo}"
  curl -s "https://berlin.mirror.pkgbuild.com/${repo}/os/x86_64/${repo}.db.tar.gz" | tar --extract --gzip --directory="${repo}"
  extract_state "${repo}" >> x86_64
  rm -rf -- "${repo}"

  mkdir "${repo}"
  tar --extract --gzip --directory="${repo}" -f ${script_dir}/pkgrepos/${repo}-staging/${repo}-staging.db.tar.gz
  extract_state "${repo}" >> staged
  rm -rf -- "${repo}"

  mkdir "${repo}"
  tar --extract --gzip --directory="${repo}" -f ${script_dir}/pkgrepos/${repo}/${repo}.db.tar.gz 
  extract_state "${repo}" >> released
  rm -rf -- "${repo}"

done
