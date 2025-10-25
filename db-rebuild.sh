#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

repo=$1
readonly repo

if [ -z "${repo}" ]; then
  echo "no repo specified"
  exit
fi

if [[ "${repo}" == *"-staging" ]]; then
  pkgrepo_path="${script_dir}/pkgrepos/${repo}"
else
  pkgrepo_path="/mnt/repo/arch/${repo}/os/aarch64"
fi

rm "${pkgrepo_path}/${repo}."*
repo-add "${pkgrepo_path}/${repo}.db.tar.gz" "${pkgrepo_path}/"*.pkg.tar.zst

