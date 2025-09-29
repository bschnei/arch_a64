#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

if ! bash "${script_dir}/pkgrepos/release.sh" "core"; then exit; fi
if ! bash "${script_dir}/pkgrepos/release.sh" "extra"; then exit; fi

if ! bash "${script_dir}/pkgrepos/push.sh" "core"; then exit; fi
if ! bash "${script_dir}/pkgrepos/push.sh" "extra"; then exit; fi
