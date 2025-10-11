#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

# unstage packages on the todo.remove list...
if [ -f "${script_dir}/todo.remove" ]; then
  echo "The following packages will be removed:"
  sed 's/^/  /' "${script_dir}/todo.remove"
  read -s -n 1 -p "Press any key to continue..."
  echo -e "\n" 
 
  while IFS= read -r line; do
    pkgrepo=$(echo ${line} | awk '{print $1}')
    pkgname=$(echo ${line} | awk '{print $2}')
    bash "${script_dir}/pkgrepos/unstage.sh" "${pkgrepo}" "${pkgname}"
  done < <(grep -v "^#" "${script_dir}/todo.remove" | grep -v "^$")
fi

rm -f -- "${script_dir}/todo.remove"

if [ ! -f "${script_dir}/todo.update" ]; then exit; fi

pkgrepos=()
pkgbases=()
pkgrefs=()

# for each package on the update list...
while IFS= read -r line; do

  pkgrepo=$(echo ${line} | awk '{print $1}')
  pkgname=$(echo ${line} | awk '{print $2}')
  pkgref=$(echo ${line} | awk '{print $3}')

  # map a package name to its base package
  pkgbase=$(pacman -Sdd "${pkgname}" --print-format %e 2>/dev/null)

  # if a package is not in the database, just use its name
  if [ -z "${pkgbase}" ]; then pkgbase=${pkgname}; fi

  # ignore package already in the list
  if echo "${pkgbases[@]}" | grep -q "${pkgbase}"; then
    continue
  fi

  pkgrepos+=("${pkgrepo}")
  pkgbases+=("${pkgbase}")
  pkgrefs+=("${pkgref}")

done < <(grep -v "^#" "${script_dir}/todo.update" | grep -v "^$")

echo "The following pkgbases will be updated, built, and staged:"
printf '  %s\n' "${pkgbases[@]}"
read -s -n 1 -p "Press any key to continue..."
echo -e "\n" 

# for each pkgbase git repo that we want to build
for (( i=0; i<${#pkgbases[@]}; i++ )); do

  bash "${script_dir}/stage.sh" "${pkgrepos[i]}" "${pkgbases[i]}" "${pkgrefs[i]}"

done
