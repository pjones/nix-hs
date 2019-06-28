#! @bash@/bin/bash

################################################################################
#
# This file is part of the package nix-hs. It is subject to the license
# terms in the LICENSE file found in the top-level directory of this
# distribution and at:
#
#   git://git.devalot.com/nix-hs.git
#
# No part of this package, including this file, may be copied, modified,
# propagated, or distributed except according to the terms contained in
# the LICENSE file.

################################################################################
set -e
set -u

################################################################################
export HASKELL_PROJECT_NAME
export HASKELL_PROJECT_DIR

################################################################################
option_compiler=default
option_ci_compilers=()
option_profiling=false
option_haddocks=false
option_debug=0
option_nixshell_args=()
option_publish=true
option_import_nixpkgs=true
option_impure=false

################################################################################
usage () {
cat <<EOF
Usage: nix-hs [options] <command>

  -c VER  Use GHC version VER (also VER,VER,VER,etc.)
  -d      Enable debugging info for nix-hs
  -h      This message
  -H      Enable building haddocks
  -i      Use an impure nix-shell
  -I PATH Add PATH to NIX_PATH
  -P      Don't publish releases [default: publish]
  -p      Enable profiling [default: off]
  -n PATH Shortcut for '-I nixpkgs=PATH' (implies -N)
  -N      Don't load nix/nixpkgs.nix

Commands:

  build:   Compile the package (default command)
  check:   Run some compliance checks on the package
  clean:   Remove all build artifacts
  release: Build and upload a package to Hackage
  repl:    Start GHCi with the package loaded
  run:     Call 'cabal run'
  shell:   Start a nix shell for the package
  test:    Compile and test the package

EOF
}

################################################################################
die() {
  echo "ERROR:" "$@" > /dev/stderr
  exit 1
}

################################################################################
banner() {
  echo
  echo "============================================================"
  echo "$@"
  echo "============================================================"
  echo
}

################################################################################
get_project_name() {
  local name
  local matches

  name=$(ls ./?*.cabal 2> /dev/null)
  matches=$(echo "$name" | wc -l)

  if [ "$matches" != 1 ]; then
    return 1
  fi

  basename "$name" .cabal
}

################################################################################
# Search for a project Cabal file, changing to the directory that
# contains it or dies.
find_project() {
  local dir
  local name

  dir=$(pwd)

  while [ "$dir" != / ]; do
    if name=$(get_project_name); then
      break
    fi

    dir=$(dirname "$dir")
    cd "$dir"
  done

  if [ "$dir" = / ]; then
    die "cannot find the .cabal file for this project"
  else
    HASKELL_PROJECT_NAME="$name"
    HASKELL_PROJECT_DIR="$dir"
  fi
}

################################################################################
# Create a proper GHC version string as used in nixpkgs.
set_compiler_version() {
  local versions=()
  mapfile -t versions < <(echo "$1" | sed -E 's/,/\n/g')

  if [ "${#versions[@]}" -gt 1 ]; then
    for ver in "${versions[@]}"; do
      option_ci_compilers+=( "$(echo "$ver" | tr -d '.')" )
    done

    option_compiler=${option_ci_compilers[0]}
  else
    option_compiler=$(echo "$1" | tr -d '.')
  fi
}

################################################################################
nix_shell() {
  local extra_options=()

  if [ -e nix/nixpkgs.nix ] && [ "$option_import_nixpkgs" = true ]; then
    extra_options+=("--arg")
    extra_options+=("pkgs")
    extra_options+=("import $(pwd)/nix/nixpkgs.nix")
  fi

  if [ "$option_debug" -eq 1 ]; then
    extra_options+=("--show-trace")
  fi

  nix-shell "${option_nixshell_args[@]}" "${extra_options[@]}" "$@"
}

################################################################################
nix_shell_extra() {
  local extra=()

  extra+=("--argstr" "file" "$(pwd)/default.nix")
  extra+=("--argstr" "compiler" "$option_compiler")
  extra+=("--arg" "profiling" "$option_profiling")

  if [ "$option_impure" = "false" ]; then
    extra+=("--pure")
  fi

  nix_shell "${extra[@]}" "$@" @interactive@
}

################################################################################
# Create/update the nix file from the cabal file.
prepare_nix_files() {
  local cabal_file=${HASKELL_PROJECT_NAME}.cabal
  local nix_file=${HASKELL_PROJECT_NAME}.nix

  if [ ! -r "$nix_file" ] || [ "$cabal_file" -nt "$nix_file" ]; then
    @cabal2nix@/bin/cabal2nix . > "$nix_file"
  fi

  if [ ! -r "default.nix" ]; then
    sed -e "s/@NIX_FILE@/${nix_file}/g" \
        < @templates@/default.nix > default.nix
  fi
}

################################################################################
run_cabal() {
  local upload_flags=()
  local upload_name="dist/${HASKELL_PROJECT_NAME}-*.tar.gz"

  if [ "$option_publish" = true ]; then
    upload_flags+=("--publish")
  fi

  prepare_nix_files

  command="${1:-build}"
  [ $# -gt 0 ] && shift

  case "$command" in
    repl)
      nix_shell_extra --command "do_cabal_repl $*"
      ;;

    check)
      echo "==> packdeps says: (checking dependency versions)"
      nix_shell -p haskellPackages.packdeps --run "packdeps ${HASKELL_PROJECT_NAME}.cabal"

      echo "==> The tested-with cabal field says: (used for Travis CI)"
      grep -i tested-with: "${HASKELL_PROJECT_NAME}.cabal" || :

      echo "==> Updating Travis CI configuration file"
      nix_shell -p multi-ghc-travis \
                --run "make-travis-yml ${HASKELL_PROJECT_NAME}.cabal > .travis.yml"
      ;;

    release)
      run_cabal clean
      run_cabal build
      nix_shell -p haskellPackages.cabal-install \
                --run "cabal v2-sdist"

      nix_shell -p haskellPackages.cabal-install \
                --run "cabal upload ${upload_flags[*]} $upload_name"
      ;;

    run)
      nix_shell_extra --command "do_cabal_run $*"
      ;;

    shell)
      nix_shell_extra
      ;;

    *)
      nix_shell_extra --command "do_cabal_$command"
      if [ "$option_haddocks" = "true" ]; then
        nix_shell_extra --command "do_cabal_haddock"
      fi
      ;;
  esac
}

################################################################################
command_supports_multiple_runs() {
  local command=$1

  case "$command" in
    build|test|clean|check)
      return 0
      ;;

    *)
      return 1
      ;;
  esac
}

################################################################################
run_tool() {
  local command=$1; shift

  if [ "${#option_ci_compilers[@]}" -gt 0 ] && \
       command_supports_multiple_runs "$command"
  then
    for ver in "${option_ci_compilers[@]}"; do
      option_compiler="$ver"
      banner "GHC: $ver"
      run_cabal "clean"
      run_cabal "$command" "$@"
    done
  else
    run_cabal "$command" "$@"
  fi
}

################################################################################
# Process the command line:
while getopts "c:dHhiI:Ppn:N" o; do
  case "${o}" in
    c) set_compiler_version "$OPTARG"
       ;;

    d) option_debug=1
       set -x
       ;;

    H) option_haddocks=true
       ;;

    h) usage
       exit
       ;;

    I) option_nixshell_args+=("-I" "$OPTARG")
       ;;

    i) option_impure=true
       ;;

    P) option_publish=false
       ;;

    p) option_profiling=true
       ;;

    n) option_nixshell_args+=("-I" "nixpkgs=$OPTARG")
       option_import_nixpkgs=false
       ;;

    N) option_import_nixpkgs=false
       ;;

    *) exit 1
       ;;
  esac
done

shift $((OPTIND-1))

################################################################################
find_project

################################################################################
# For tools that treat this script like `cabal':
if [ "${1:-build}" = cabal ]; then shift; fi

################################################################################
# Main dispatch code:
command="${1:-build}"
if [ $# -gt 0 ]; then shift; fi
if [ "${1:-}" = "--" ]; then shift; fi

case "$command" in
  new-build|build)
    run_tool "build" "$@"
    ;;

  new-repl|repl)
    run_tool "repl" "$@"
    ;;

  new-test|test)
    run_tool "test" "$@"
    ;;


  shell|clean|check|release)
    run_tool "$command" "$@"
    ;;

  run)
    run_tool "$command" "$@"
    ;;

  *)
    die "unknown command: $1"
    ;;
esac
