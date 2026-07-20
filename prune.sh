#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

pkgrepo_path="${script_dir}/pkgrepos"
state_path="${script_dir}/state"
readonly pkgrepo_path state_path

printf "%s" "Looking for packages to prune..."

repos=("core" "extra")
for repo in "${repos[@]}"; do

  # load the state of the repos from disk
  upstream=$(< "${state_path}/${repo}")
  released=$(tar -tvf "${script_dir}/pkgrepos/${repo}/${repo}.db.tar.zst" | grep -e "^d" | awk '{print $6}' | sed 's/.$//')

  # for each package in ${released}...
  while IFS= read -r pkg; do

    # each line in ${released} is formatted as: pkgname-pkgver
    # e.g. linux-6.16.7-arch1
    pkgname=$(echo "${pkg}" | sed -E 's/-[^-]+-[^-]+$//')

    # pkgver from upstream
    pkgver_upstream=$(echo "${upstream}" | awk -v name="${pkgname}" '$1 == name' | awk '{print $2}')

    # if our package is not found in the upstream repo, we need to remove
    if [ -z "${pkgver_upstream}" ]; then
      # don't prune aarch64-only packages
      if grep -Fxq "${pkgname}" "${script_dir}/pkglist/whitelist"; then continue; fi
      toremove+=("${repo} ${pkgname}")
    fi

  done <<< "${released}"

done

if [ ${#toremove[@]} -eq 0 ]; then
  printf "%s\n" "nothing to prune!"
  exit
fi

printf "\n%s\n" "The following packages will be removed:"
printf "  %s\n" "${toremove[@]}"
read -s -n 1 -p "Press any key to continue..."
printf "\n"

for item in "${toremove[@]}"; do
  pkgrepo=$(echo "${item}" | cut -d ' ' -f 1)
  pkgname=$(echo "${item}" | cut -d ' ' -f 2)
  repo-remove "${pkgrepo_path}/${pkgrepo}/${pkgrepo}.db.tar.zst" "${pkgname}"
  find "${pkgrepo_path}/${pkgrepo}/" -type f -regextype posix-extended -regex ".*/${pkgname}-[^-]+-[^-]+-[^-]+.pkg.tar.zst" -delete
  find "${pkgrepo_path}/${pkgrepo}/" -type f -regextype posix-extended -regex ".*/${pkgname}-[^-]+-[^-]+-[^-]+.pkg.tar.zst.sig" -delete
done
