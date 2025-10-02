#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo .)")" || exit; pwd)
readonly script_dir

sudo rm -rf -- ben ben.lock root root.lock
mkarchroot -s -C "${script_dir}/pacman.conf" -M "${script_dir}/makepkg.conf" "${script_dir}/root" base-devel

