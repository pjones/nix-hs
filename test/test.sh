#! /usr/bin/env nix-shell
#! nix-shell -i bash shell.nix
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

    if [ "$static" != "static" ]; then
      # Create an interactive development environment.  Since we use
      # the same tools in both static and dynamic builds, don't test
      # the tools in static mode.  This is to keep the disk space
      # lower for GitHub Actions.
      nix-shell \
        "${args[@]}" \
        "$package/shell.nix" \
        --run "cabal --version"
    fi
  done

  # Load an interactive development environment that isn't connected
  # to a nix-hs controlled project.
  nix-shell \
    --argstr compiler "$compiler" \
    "$top/../nix/shell.nix" \
    --run "ghcide --version"

  # Check the `bin' attribute:
  nix-build \
    --no-out-link \
    "${args[@]}" \
    "$top/hello-world/release.nix"
}

################################################################################
if [ $# -eq 0 ]; then
  for compiler in $(jq -r 'keys|join(" ")' "$top/../compilers.json"); do
    run_test "$compiler" "dynamic"
    run_test "$compiler" "static"
  done
elif [ $# -eq 1 ]; then
  run_test "$1" "dynamic"
  run_test "$1" "static"
elif [ $# -eq 2 ]; then
  run_test "$1" "$2"
else
  echo >&2 "ERROR: invalid arguments"
  exit 1
fi

# Local Variables:
#   mode: sh
#   sh-shell: bash
# End:
