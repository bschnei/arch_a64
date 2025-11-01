#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

. "$(dirname "$(readlink -e "$0")")/functions"

pkgrepo_path="${script_dir}/pkgrepos"
state_path="${script_dir}/state"
readonly pkgrepo_path state_path

# for each repo
repos=("core" "extra")
for repo in "${repos[@]}"; do

  echo "Syncing 'any' packages in [${repo}]..."

  # load the state of the repos from disk
  upstream=$(awk '$4 == "any" {print $1,$2,$3}' "${state_path}/${repo}")
  staged=$(tar -tvzf "${script_dir}/pkgrepos/${repo}-staging/${repo}-staging.db.tar.gz" | grep -e "^d" | awk '{print $6}' | sed 's/.$//')
  released=$(tar -tvzf "${script_dir}/pkgrepos/${repo}/${repo}.db.tar.gz" | grep -e "^d" | awk '{print $6}' | sed 's/.$//')

  # for each 'any' package ${upstream}...
  while IFS= read -r line; do

    # formatted as: pkgname pkgver pkgbase pkgarch
    if [ -z "${line}" ]; then continue; fi
    pkgname=$(echo "${line}" | cut -d ' ' -f 1)
    pkgver=$(echo "${line}" | cut -d ' ' -f 2)

    # + is a special character for regex that can be in pkgname
    # so escape it when parsing out pkgver
    pattern=$(echo "${pkgname}" | sed 's/+/\\+/g')   
    released_ver=$(echo "${released}" | grep -E -m 1 "^${pattern}-[^-]+-[^-]+$" | sed -E "s/^${pattern}-//")

    # if versions match, go to next package
    if [[ "${pkgver}" == "${released_ver}" ]]; then continue; fi

    # skip packages on ignore list
    if grep -Fxq "${pkgname}" "${script_dir}/pkglist/ignore"; then continue; fi
    
    # download newer version to staging
    if ! rsync -Lavh "rsync://berlin.mirror.pkgbuild.com/packages/${repo}/os/x86_64/${pkgname}-${pkgver}-any.pkg.tar.*" "${pkgrepo_path}/${repo}-staging/"; then continue; fi
    # update staging package database
    repo-add --remove "${pkgrepo_path}/${repo}-staging/${repo}-staging.db.tar.gz" "${pkgrepo_path}/${repo}-staging/${pkgname}-${pkgver}-any.pkg.tar.zst"

    # download newer version
    if ! rsync -Lavh "rsync://berlin.mirror.pkgbuild.com/packages/${repo}/os/x86_64/${pkgname}-${pkgver}-any.pkg.tar.*" "${pkgrepo_path}/${repo}/"; then continue; fi
    # update package database
    repo-add --remove "${pkgrepo_path}/${repo}/${repo}.db.tar.gz" "${pkgrepo_path}/${repo}/${pkgname}-${pkgver}-any.pkg.tar.zst"

  done <<< "${upstream}"

done
