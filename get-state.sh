#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

. "$(dirname "$(readlink -e "$0")")/functions"

cd state || exit

repos=("core" "extra")
readonly repos

for repo in "${repos[@]}"; do

  echo "Processing [${repo}] database..."

  curl -s -O "https://berlin.mirror.pkgbuild.com/${repo}/os/x86_64/${repo}.db.tar.gz"
  extract_state "${repo}.db.tar.gz" > "${repo}.x86_64"
  rm -- "${repo}.db.tar.gz"

done
