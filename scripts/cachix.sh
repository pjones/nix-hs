#! /usr/bin/env nix-shell
#! nix-shell -i bash -p jq cachix
# shellcheck shell=bash

################################################################################
set -e
set -u
set -x

################################################################################
top=$(realpath "$(dirname "$0")/..")

################################################################################
cachix_push() {
  compiler=$1
  static=$2

  args=("--argstr" "compiler" "$compiler")

  if [ "$static" = "static" ]; then
    args+=("--arg" "static" "true")
  fi

  nix-build \
    --no-out-link \
    "${args[@]}" \
    "$top/test/hello-world" |
    cachix push nix-hs

  nix-build \
    --no-out-link \
    "${args[@]}" \
    "$top/test/hello-world/shell.nix" |
    cachix push nix-hs
}

################################################################################
for compiler in $(jq -r 'keys|join(" ")' "$top/compilers.json"); do
  cachix_push "$compiler" "dynamic"
  cachix_push "$compiler" "static"
done

# Local Variables:
#   mode: sh
#   sh-shell: bash
# End:
