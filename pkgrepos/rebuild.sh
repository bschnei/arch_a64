#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

repo=$1
readonly repo

if [ -z "${repo}" ]; then
  echo "no repo specified"
  exit
fi

pkgrepo_path="${script_dir}/${repo}"
readonly pkgrepo_path

rm "${pkgrepo_path}/${repo}."*
repo-add "${pkgrepo_path}/${repo}.db.tar.zst" "${pkgrepo_path}/"*.pkg.tar.zst

