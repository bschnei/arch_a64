#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

repo=$1
readonly repo

if [ -z $repo ]; then
  echo "no repo specified"
  exit
fi

rsync -avh --delete "${script_dir}/${repo}/" "repo.bens.haus:/mnt/repo/arch/${repo}/os/aarch64/"
