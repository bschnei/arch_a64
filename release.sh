#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

repos=("core" "extra")
readonly repos

for repo in "${repos[@]}"; do

  from="${script_dir}/pkgrepos/${repo}-staging/"
  to="${script_dir}/pkgrepos/${repo}/"

  rsync -avh --delete --exclude "${repo}".* --exclude "${repo}-staging".* "${from}" "${to}"

  bash "${script_dir}/pkgrepos/rebuild.sh" "${repo}"

done
