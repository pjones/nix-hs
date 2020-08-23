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

  nix-build \
    --no-out-link \
    "${args[@]}" \
    "$top/test/hello-world/shell.nix" |
    cachix push nix-hs

  # Ensure that GHC is cached so that GitHub actions don't run out of
  # disk space while trying building it.  Primarily for the statically
  # linked versions of GHC.
  ghc=$(nix-shell "${args[@]}" "$top/test/hello-world/default.nix" --run "type -p ghc")
  path=$(dirname "$(dirname "$ghc")")
  cachix push nix-hs "$path"
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
