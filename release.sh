#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

pkgrepo_path="${script_dir}/pkgrepos"
readonly pkgrepo_path

# for each repo
repos=("core" "extra")
for repo in "${repos[@]}"; do

  if ! test -n "$(find "${pkgrepo_path}/${repo}-staging/" -maxdepth 1 -name '*.pkg.tar.zst' -print -quit)"; then continue; fi

  # move *.pkg files from staging to release
  readarray -t pkgfiles < <(rsync \
    --itemize-changes \
    --times \
    --remove-source-files \
    "${pkgrepo_path}/${repo}-staging/"*.pkg.tar.zst "${pkgrepo_path}/${repo}/" | awk '{print $2}')
 
  # rebuild staging database
  rm "${pkgrepo_path}/${repo}-staging/${repo}"-staging.*
  repo-add "${pkgrepo_path}/${repo}-staging/${repo}-staging.db.tar.gz"

  # update the release database
  pkglist=$(printf "${pkgrepo_path}/${repo}/%s " "${pkgfiles[@]}")
  repo-add --remove -p "${pkgrepo_path}/${repo}/${repo}.db.tar.gz" ${pkglist[@]}

done
