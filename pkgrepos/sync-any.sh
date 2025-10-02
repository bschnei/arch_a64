#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

rsync -Lavh --delete "rsync://berlin.mirror.pkgbuild.com/packages/core/os/x86_64/*-any.pkg.tar*" "${script_dir}/core-staging/"
bash "${script_dir}/rebuild.sh" "core-staging"

rsync -Lavh --delete --exclude aarch64-* "rsync://berlin.mirror.pkgbuild.com/packages/extra/os/x86_64/*-any.pkg.tar*" "${script_dir}/extra-staging/"
bash "${script_dir}/rebuild.sh" "extra-staging"
