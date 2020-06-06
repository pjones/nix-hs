#! /usr/bin/env nix-shell
#! nix-shell -i bash -p jq
# shellcheck shell=bash

################################################################################
set -e
set -u
set -x

################################################################################
top=$(realpath "$(dirname "$0")")

################################################################################
run_test() {
  compiler=$1
  static=$2

  args=("--argstr" "compiler" "$compiler")

  if [ "$static" = "static" ]; then
    args+=("--arg" "static" "true")
  fi

  for package in "$top/hello-world" "$top/multi-package"; do
    # Build a package:
    nix-build \
      --no-out-link \
      "${args[@]}" \
      "$package"

    # Create an interactive development environment:
    nix-shell \
      "${args[@]}" \
      "$package/shell.nix" \
      --run "cabal --version"
  done

  # Load an interactive development environment that isn't connected
  # to a nix-hs controlled project.
  nix-shell \
    --argstr compiler "$compiler" \
    "$top/../nix/shell.nix" \
    --run "ghcide --version"
}

################################################################################
for compiler in $(jq -r 'keys|join(" ")' "$top/../compilers.json"); do
  run_test "$compiler" "dynamic"
  run_test "$compiler" "static"
done

# Local Variables:
#   mode: sh
#   sh-shell: bash
# End:
