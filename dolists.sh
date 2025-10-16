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

pkgnames=()
pkgvers=()
pkgrepos=()
pkgbases=()
pkgarchs=()

# for each package on the update list...
while IFS= read -r line; do

  pkgname=$(echo ${line} | awk '{print $1}')
  pkgver=$(echo ${line} | awk '{print $2}')
  pkgrepo=$(echo ${line} | awk '{print $3}')
  pkgbase=$(echo ${line} | awk '{print $4}')
  pkgarch=$(echo ${line} | awk '{print $5}')

  # TODO: handle "special" packages

  # ignore pkgbase already in the list
  if [ "$pkgarch" != "any" ] && echo "${pkgbases[@]}" | grep -q "${pkgbase}"; then
    continue
  fi

  pkgnames+=("${pkgname}")
  pkgvers+=("${pkgver}")
  pkgrepos+=("${pkgrepo}")
  pkgbases+=("${pkgbase}")
  pkgarchs+=("${pkgarch}")

done < <(grep -v "^#" "${script_dir}/todo.update" | grep -v "^$")

echo "The following pkgbases will be updated, built, and staged:"
printf '  %s\n' "${pkgnames[@]}"
read -s -n 1 -p "Press any key to continue..."
echo -e "\n" 

for (( i=0; i<${#pkgnames[@]}; i++ )); do

  bash "${script_dir}/stage.sh" "${pkgnames[i]}" "${pkgvers[i]}" "${pkgrepos[i]}" "${pkgbases[i]}" "${pkgarchs[i]}"

done
