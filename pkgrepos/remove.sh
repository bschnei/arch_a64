#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

state_path="${script_dir}/state"
readonly state_path

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

for repo in ("${pkgrepo}-staging" "${pkgrepo}"); do

  # remove from database
  repo-remove "${script_dir}/${repo}/${repo}.db.tar.gz" "${pkgname}"
  
  # remove package file and signature
  find "${script_dir}/${repo}" -type f -regextype posix-extended -regex ".*/${pkgname}-[^-]+-[^-]+-[^-]+.pkg.tar.zst" -delete
  find "${script_dir}/${repo}" -type f -regextype posix-extended -regex ".*/${pkgname}-[^-]+-[^-]+-[^-]+.pkg.tar.zst.sig" -delete
  
done

# update downstream state files
pattern=$(echo "${pkgname}" | sed 's/+/\\+/g')   
sed -i "/^remove ${pattern} ${pkgrepo}$/d" "${state_path}/todo"

