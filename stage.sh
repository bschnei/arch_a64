#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

repo="${1}"
pkgbase="${2}"
gitref="${3-main}"

if ! bash "${script_dir}/build.sh" "${pkgbase}" "${gitref}"; then exit; fi

pkgrepo_path="${script_dir}/pkgrepos/${repo}-staging"
srcrepo_path="${script_dir}/srcrepos/${pkgbase}"
readonly srcrepo_path pkgrepo_path 

# add built packages to staging repo
cd "${srcrepo_path}" || exit
for pkg in *.pkg.tar.*; do
  mv "${pkg}" "${pkgrepo_path}"
  repo-add --remove "${pkgrepo_path}/${repo}-staging.db.tar.gz" "${pkgrepo_path}/${pkg}"
done

# remove build artifacts
cd .. || exit
rm -rf -- "${pkgbase}"

