#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

pkgrepos_path="${script_dir}/pkgrepos"
state_path="${script_dir}/state"
readonly pkgrepos_path state_path

pkgname="${1}"
pkgrepo="${2}"
readonly pkgname pkgrepo

if [ -z "${pkgname}" ]; then
  echo "remove.sh: no package name specified"
  exit
fi

if [ -z "${pkgrepo}" ]; then
  echo "remove.sh: no package repo specified"
  exit
fi

repos=("${pkgrepo}-staging" "${pkgrepo}")
for repo in "${repos[@]}"; do

  # remove from database
  repo-remove "${pkgrepos_path}/${repo}/${repo}.db.tar.gz" "${pkgname}"
  
  # remove package file and signature
  find "${pkgrepos_path}/${repo}" -type f -regextype posix-extended -regex ".*/${pkgname}-[^-]+-[^-]+-[^-]+.pkg.tar.zst" -delete
  find "${pkgrepos_path}/${repo}" -type f -regextype posix-extended -regex ".*/${pkgname}-[^-]+-[^-]+-[^-]+.pkg.tar.zst.sig" -delete
  
done

# update downstream state files
pattern=$(echo "${pkgname}" | sed 's/+/\\+/g')   
sed -i "/^remove ${pattern} ${pkgrepo}$/d" "${state_path}/todo"

