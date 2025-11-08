#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

pkgrepo_path="${script_dir}/pkgrepos"
state_path="${script_dir}/state"
readonly pkgrepo_path state_path

# TODO: warn if there are outstanding todos?

# clear old torelease list
rm -f -- "${state_path}/torelease"

repos=("core" "extra")
for repo in "${repos[@]}"; do

  printf "%s" "Looking for packages in [${repo}-staging]..."

  # load the state of the repos from disk
  staged=$(tar -tvzf "${script_dir}/pkgrepos/${repo}-staging/${repo}-staging.db.tar.gz" | grep -e "^d" | awk '{print $6}' | sed 's/.$//')
  released=$(tar -tvzf "${script_dir}/pkgrepos/${repo}/${repo}.db.tar.gz" | grep -e "^d" | awk '{print $6}' | sed 's/.$//')

  # for each package in ${staged}...
  while IFS= read -r pkg; do

    if [ -z "${pkg}" ]; then continue; fi

    # each line in ${staged} is formatted as: pkgname-pkgver
    # e.g. linux-6.16.7-arch1
    pkgname=$(echo "${pkg}" | sed -E 's/-[^-]+-[^-]+$//')

    # + is a special character for regex that can be in pkgname
    # so escape it when parsing out pkgver
    pattern=$(echo "${pkgname}" | sed 's/+/\\+/g')   
    pkgver=$(echo "${pkg}" | sed -E "s/^${pattern}-//")

    echo "${pkgname} ${pkgver} ${repo}" >> "${state_path}/torelease"

  done <<< "${staged}"

  printf "%s\n" "done!"

done

if [ ! -f "${state_path}/torelease" ]; then exit; fi
if [ ! -s "${state_path}/torelease" ]; then exit; fi

# load packages to be released from torelease list
releases=$(< "${state_path}/torelease")

echo "The following packages will be released:"
sed 's/^/  /' "${state_path}/torelease"
read -s -n 1 -p "Press any key to continue..."
echo -e "\n" 

while IFS= read -r line; do

  pkgname=$(echo "${line}" | cut -d ' ' -f 1)
  pkgver=$(echo "${line}" | cut -d ' ' -f 2)
  pkgrepo=$(echo "${line}" | cut -d ' ' -f 3)

  src="${pkgrepo_path}/${pkgrepo}-staging/${pkgname}-${pkgver}-*"
  dest="${pkgrepo_path}/${pkgrepo}"

  rsync -av --remove-source-files ${src} ${dest}/
  pkgfile="${dest}/${pkgname}-${pkgver}-*.pkg.tar.zst"
  repo-add --remove "${dest}/${pkgrepo}.db.tar.gz" ${pkgfile}
  repo-remove "${dest}-staging/${pkgrepo}-staging.db.tar.gz" "${pkgname}"

done <<< "${releases}"

# clear torelease list
rm -f -- "${state_path}/torelease"
