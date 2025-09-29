#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

repo=$1
readonly repo

if [ -z "${repo}" ]; then
  echo "no repo specified"
  exit
fi

from="${repo}-staging"
to="${repo}"
readonly from to

rsync -avh --delete --exclude ${to}.* --exclude ${from}.* "${script_dir}/${from}/" "${script_dir}/${to}/"

bash "${script_dir}/rebuild.sh" "${repo}"
