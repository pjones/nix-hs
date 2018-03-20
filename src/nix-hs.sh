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
option_profiling=false
option_debug=0
option_tool=""
option_nixshell_args=()

################################################################################
usage () {
cat <<EOF
Usage: nix-hs [options] (build|test|clean|repl|shell)

  -c VER  Use GHC version VER
  -d      Enable debugging info for nix-hs
  -h      This message
  -I PATH Add PATH to NIX_PATH
  -p      Enable profiling [default: off]
  -n PATH Shortcut for '-I nixpkgs=PATH'
  -t TYPE Force using build type TYPE (cabal|stack|make)
EOF
}

################################################################################
die() {
  echo "ERROR:" "$@" > /dev/stderr
  exit 1
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
# Check to see if the project root is *not* the same directory as the
# project directory.  This is a common directory layout with stack
# where one stack.yaml file is used to point to several projects.
find_stack_root() {
  # See if the parent directory has a stack file:
  export STACK_YAML=${STACK_YAML:-stack.yaml}

  if [ -r "$STACK_YAML" ]; then
    return 0
  elif [ ! -r "$STACK_YAML" ] && [ -r ../"$STACK_YAML" ]; then
    export STACK_YAML="../$STACK_YAML"
    return 0
  fi

  return 1
}

################################################################################
nix_shell() {
  local extra_options=()

  if [ "$option_debug" -eq 1 ]; then
    extra_options+=("--show-trace")
  fi

  # FIXME: support all interactive.nix options.

  nix-shell --pure "$@" \
            --argstr file "$(pwd)/default.nix" \
            --argstr compiler "$option_compiler" \
            --arg profiling "$option_profiling" \
            "${option_nixshell_args[@]}" "${extra_options[@]}" \
            @interactive@
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
    sed -e "s/@PROJECT@/${HASKELL_PROJECT_NAME}/g" \
        < @templates@/default.nix > default.nix
  fi
}

################################################################################
# If needed, run `cabal configure'.
cabal_configure() {
  local cabal_file=${HASKELL_PROJECT_NAME}.cabal
  local datestamp=dist/.configure-run-date

  if [ ! -r "$datestamp" ] || [ "$cabal_file" -nt "$datestamp" ]; then
    nix_shell --command "do_cabal_configure"
    date > dist/.configure-run-date
  fi
}

################################################################################
run_cabal() {
  prepare_nix_files
  cabal_configure

  case "${1:-build}" in
    repl)
      nix_shell --command "do_cabal_repl lib:$HASKELL_PROJECT_NAME"
      ;;

    shell)
      nix_shell
      ;;

    *)
      nix_shell --command "do_cabal_$1"
      ;;
  esac
}

################################################################################
# TOOL: stack
run_stack() {
  prepare_nix_files
  local stack_flags=()

  if [ "$option_profiling" = true ]; then
    if [ "${1:-build}" = build ]; then
      stack_flags+=("--library-profiling")
      stack_flags+=("--executable-profiling")
    fi
  fi

  case "${1:-build}" in
    shell)
      nix_shell
      ;;

    *)
      @stack@/bin/stack \
        --nix --nix-shell-file=@stacknix@ \
        --nix-shell-options "--argstr file $(pwd)/default.nix" \
        "$@" "${stack_flags[@]}"
      ;;
  esac
}

################################################################################
# TOOL: make
run_make() {
  case "${1:-build}" in
    build)
      make
      ;;

    *)
      make "$@"
      ;;
  esac
}

################################################################################
# Process the command line:
while getopts "c:dhI:pn:t:" o; do
  case "${o}" in
    c) option_compiler=$(echo "$OPTARG" | tr -d '.')
       ;;

    d) option_debug=1
       set -x
       ;;

    h) usage
       exit
       ;;

    I) option_nixshell_args+=("-I" "$OPTARG")
       ;;

    p) option_profiling=true
       ;;

    n) option_nixshell_args+=("-I" "nixpkgs=$OPTARG")
       ;;

    t) option_tool=$OPTARG
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
if [ "${1:-build}" = cabal ] && [ "$#" -eq 2 ]; then shift; fi

################################################################################
# Figure out which tool we should be using:
if [ -n "$option_tool" ]; then
  tool=$option_tool
else
  if find_stack_root; then
    tool=stack
  elif [ -r Makefile ] || [ -r GNUmakefile ]; then
    tool=make
  else
    tool=cabal
  fi
fi

case "$tool" in
  cabal)
    : # No settings needed
    ;;

  stack)
    : # No settings needed
    ;;

  make)
    : # No settings needed
    ;;

  *)
    die "unknown build tool: $tool"
    ;;
esac

################################################################################
# Main dispatch code:
command="${1:-build}"
if [ $# -gt 0 ]; then shift; fi
if [ "${1:-}" = "--" ]; then shift; fi

case "$command" in
  new-build|build)
    "run_${tool}" build "$@"
    ;;

  test)
    "run_${tool}" test "$@"
    ;;

  clean)
    "run_${tool}" clean "$@"
    ;;

  new-repl|repl)
    "run_${tool}" repl "$@"
    ;;

  shell)
    "run_${tool}" shell "$@"
    ;;

  *)
    die "unknown command: $1"
    ;;
esac
