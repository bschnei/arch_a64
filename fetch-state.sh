#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

extract_state () {

  tmp_dir=$(mktemp --directory)
  tar --extract --gzip --directory="${tmp_dir}" -f "${1}"

  for pkg in "${tmp_dir}"/*/desc; do

    pkgdesc=$(< "${pkg}")

    pkgname=$(echo "${pkgdesc}" | awk '/%NAME%/{getline; print}')
    pkgbase=$(echo "${pkgdesc}" | awk '/%BASE%/{getline; print}')
    pkgver=$(echo "${pkgdesc}" | awk '/%VERSION%/{getline; print}')
    pkgarch=$(echo "${pkgdesc}" | awk '/%ARCH%/{getline; print}')

    echo "${pkgname} ${pkgver} ${pkgbase} ${pkgarch}"

  done

  rm --recursive -- "${tmp_dir}"
}

cd "${script_dir}/state" || exit

repos=("core" "extra")
readonly repos

for repo in "${repos[@]}"; do

  (
    url="https://berlin.mirror.pkgbuild.com/${repo}/os/x86_64/${repo}.db.tar.gz"

    if ! curl -s -O "${url}"; then
      echo "Failed to download ${url}"
      exit
    fi
  ) &

done
wait

printf "%s" "Building upstream state files..."

for repo in "${repos[@]}"; do
  (
    extract_state "${repo}.db.tar.gz" > "${repo}"
    rm -- "${repo}.db.tar.gz"
  ) &
done
wait

printf "%s\n" "done!"

