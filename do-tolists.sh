#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

# unstage packages on the to.unstage list...
if [ $(grep -cve '^\\s*$' "${script_dir}/to.unstage") -gt 0 ]; then
  echo "The following packages will be removed:"
  sed 's/^/  /' "${script_dir}/to.unstage"
  read -s -n 1 -p "Press any key to continue..."
  echo -e "\n" 
 
  while IFS= read -r line; do

    pkgname=$(echo ${line} | awk '{print $1}')
    pkgrepo=$(echo ${line} | awk '{print $2}')
    bash "${script_dir}/pkgrepos/unstage.sh" "${pkgname}" "${pkgrepo}"

    # remove from to.unstage list
    pattern=$(echo "${pkgname}" | sed 's/+/\\+/g')   
    sed -i "/${pattern}/d" "${script_dir}/to.unstage"

  done < <(grep -v "^#" "${script_dir}/to.unstage" | grep -v "^$")

fi

# for each package on the to.stage list...
if [ $(grep -cve '^\\s*$' "${script_dir}/to.stage") -gt 0 ]; then
  echo "The following packages will be staged:"
  sed 's/^/  /' "${script_dir}/to.stage"
  read -s -n 1 -p "Press any key to continue..."
  echo -e "\n"

  while IFS= read -r pkgname; do

    # TODO: handle "special" packages
    bash "${script_dir}/stage.sh" "${pkgname}"

    # remove from to.stage list
    pattern=$(echo "${pkgname}" | sed 's/+/\\+/g')   
    sed -i "/${pattern}/d" "${script_dir}/to.stage"

  done < <(grep -v "^#" "${script_dir}/to.stage" | grep -v "^$")

fi
