#!/usr/bin/env bash

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
    nix-build \
      --no-out-link \
      "${args[@]}" \
      "$package"

    nix-shell \
      "${args[@]}" \
      "$package/shell.nix" \
      --run "cabal --version"
  done
}

################################################################################
run_test "865" "dynamic"
run_test "865" "static"

run_test "883" "dynamic"
run_test "883" "static"

run_test "8101" "dynamic"
#run_test "ghc8101" "static"
