#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

pkgrepos_path="${script_dir}/pkgrepos/"
from="staging"
to="testing"
readonly pkgrepos_path from to

rsync -avh --delete --exclude ${to}.* --exclude ${from}.* "${pkgrepos_path}/${from}/" "${pkgrepos_path}/${to}/"

rm "${pkgrepos_path}/${to}/${to}."*
if ! repo-add "${script_dir}/pkgrepos/testing/testing.db.tar.gz" "${script_dir}"/pkgrepos/testing/*.pkg.*; then exit; fi

bash "${script_dir}/pkgrepos/push.sh" "testing"
