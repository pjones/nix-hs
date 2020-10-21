#! /usr/bin/env nix-shell
#! nix-shell -i bash ../shell.nix
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

  nix-store \
    --query --references \
    "$(nix-instantiate "${args[@]}" "$top/test/hello-world/shell.nix")" |
    xargs nix-store --realise |
    xargs nix-store --query --requisites |
    tee /dev/stderr |
    cachix push nix-hs
}

################################################################################
compilers=()

readarray -t compilers < <(
  jq -r \
    'map_values(select(.lts))|keys|join(" ")' \
    <"$top/compilers.json"
)

for compiler in "${compilers[@]}"; do
  cachix_push "$compiler" "dynamic"
  cachix_push "$compiler" "static"
done

# Local Variables:
#   mode: sh
#   sh-shell: bash
# End:
