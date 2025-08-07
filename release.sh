#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

rsync -avh --delete --exclude staging.* --exclude testing.* "${script_dir}/pkgrepos/staging/" "${script_dir}/pkgrepos/testing/"

rm "${script_dir}"/pkgrepos/testing/testing.*
repo-add "${script_dir}/pkgrepos/testing/testing.db.tar.gz" "${script_dir}"/pkgrepos/testing/*.pkg.*
