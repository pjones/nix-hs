#! /usr/bin/env nix-shell
#! nix-shell -i bash ../shell.nix
# shellcheck shell=bash

################################################################################
set -e
set -u
set -x

################################################################################
top=$(realpath "$(dirname "$0")")
packages=("$top/hello-world" "$top/multi-package")

################################################################################
run_build() {
  package=$1
  shift

  nix-build \
    --no-out-link \
    "${@}" \
    "$package"
}

################################################################################
run_tool() {
  package=$1
  shift

  tool=$1
  shift

  nix-shell \
    "${@}" \
    "$package" \
    --run "$tool"
}

################################################################################
run_test() {
  compiler=$1
  binary=$2
  args=("--argstr" "compiler" "$compiler")

  if [ "$binary" = "static" ]; then
    args+=("--arg" "static" "true")
  fi

  for package in "${packages[@]}"; do
    # Build a package:
    run_build "$package" "${args[@]}"
  done

  # Check the `bin' attribute:
  run_build "$top/hello-world" "${args[@]}" -A bin

  # Create an interactive development environment.  Since we use
  # the same tools in both static and dynamic builds, don't test
  # the tools in static mode.  This is to keep the disk space
  # lower for GitHub Actions.
  if [ "$binary" != "static" ]; then
    for package in "${packages[@]}"; do
      run_tool "$package/shell.nix" "cabal --version" "${args[@]}"
    done

    # Load an interactive development environment that isn't connected
    # to a nix-hs controlled project.
    run_tool "$top/../nix/shell.nix" "ghcide --version" "${args[@]}"
  fi
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
