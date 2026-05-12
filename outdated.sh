#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

state_path="${script_dir}/state"
outdated_file="${script_dir}/pkglist/outdated"
hold_file="${script_dir}/pkglist/hold"
readonly state_path outdated_file hold_file

# load list of packages we are holding off on building
declare -A on_hold
if [[ -f "$hold_file" ]]; then
  while read -r line; do
    line=$(echo "$line" | xargs)
    [[ -z "$line" || "$line" == \#* ]] && continue
    on_hold["$line"]=1
  done < "$hold_file"
fi

# remove any old outdated pkglist
: > "$outdated_file"

printf "Building pkglist/outdated..."

repos=("core" "extra")
for repo in "${repos[@]}"; do

  # load versions and architectures of all upstream packages
  declare -A pkgver pkgarch
  while read -r name ver _ arch; do
    pkgver["$name"]="$ver"
    pkgarch["$name"]="$arch"
  done < "${state_path}/${repo}"

  # load versions of packages in staging repo
  declare -A staged
  while read -r entry; do
    entry="${entry%/}"
    p_name="${entry%-*-*}"
    p_ver="${entry#$p_name-}"
    staged["$p_name"]="$p_ver"
  done < <(tar -tf "${script_dir}/pkgrepos/${repo}-staging/${repo}-staging.db.tar.gz" | grep '/$')

  # for each package released
  while read -r entry; do
    entry="${entry%/}"
    pkgname="${entry%-*-*}"
    pkgver_released="${entry#$pkgname-}"
    pkgver_upstream="${pkgver[$pkgname]}"

    # skip 'any' packages
    [[ "${pkgarch[$pkgname]}" == "any" ]] && continue

    # skip packages on hold list
    [[ -n "${on_hold[$pkgname]}" ]] && continue

    # skip packages not found upstream
    [[ -z "$pkgver_upstream" ]] && continue

    # compare versions
    state=$(vercmp "$pkgver_upstream" "$pkgver_released")
    if (( state > 0 )); then
      # if upstream is newer, check if staging already has it
      if [[ "${staged[$pkgname]}" != "$pkgver_upstream" ]]; then
        echo "$pkgname" >> "$outdated_file"
      fi
    fi

  done < <(tar -tf "${script_dir}/pkgrepos/${repo}/${repo}.db.tar.gz" | grep '/$')

  # cleanup arrays for next repo
  unset pkgver pkgarch staged
done

echo "done!"
