################################################################################
#
# This file is part of the package nix-hs. It is subject to the license
# terms in the LICENSE file found in the top-level directory of this
# distribution and at:
#
#   https://code.devalot.com/open/nix-hs
#
# No part of this package, including this file, may be copied, modified,
# propagated, or distributed except according to the terms contained in
# the LICENSE file.
#
{ pkgs ? import <nixpkgs> { }
}:

{
  # Path to one or more Cabal files.  May be a single path or an attr
  # set of package names and paths to cabal files:
  cabal,

  # Cabal `-f' flags to use:
  flags ? [],

  # Optional: Override `haskellPackages' with a function.  The
  # function takes three arguments and returns a new package set.
  #
  # The arguments are:
  #
  # 1. `pkgs.haskell.lib` with some additions.
  # 2. `self`: The package set you are currently building.
  # 3. `super`: The existing Haskell package set.
  overrides ? (lib: self: super: {}),

  # Extra nixpkgs packages that your Haskell package depend on:
  buildInputs ? [],

  # Shell fragment to run after the `patchPhase':
  postPatch ? "",

  # Whether or not to build completely static executables.
  #
  # Very experimental.  Often broken.  See:
  # https://github.com/nh2/static-haskell-nix
  enableFullyStaticExecutables ? false,

  # If not null, it should be a function that takes a path to the data
  # directory and returns shell code to install extra files.
  #
  # Note: The argument given to this function contains shell variables
  # so it can only be used in a shell snippet.
  #
  # Example:
  #
  #    addDataFiles = path: ''
  #      mkdir -p "${path}/www"
  #      for file in ${ui}/*.js; do
  #        install -m 0444 "$file" "${path}/www"
  #      done
  #    '';
  addDataFiles ? null,

  # A nixpkgs version string for GHC, or "default":
  compiler ? "default"
}:

let

  # The package set to start with.
  pkgs_ = if enableFullyStaticExecutables
            then pkgs.pkgsMusl
            else pkgs;

  # Some library functions:
  lib = import ./nix/lib.nix {
    pkgs = pkgs_ // {
      haskellPackages = haskell;
      haskell = pkgs_.haskell // {
        packages = pkgs_.haskell.packages // {
          "${compilerName}" = haskell;
        };
      };
    };
  };

  # Modified version of the nixpkgs Haskell lib:
  hlib = pkgs_.haskell.lib // {
    inherit (lib) pkgs unBreak fetchGit addPostPatch;
    inherit compilerName;
  };

  # Calculate the name of the compiler we're going to use.
  compilerName =
    if compiler == "default"
    then builtins.replaceStrings ["." "-"] ["" ""] pkgs_.haskellPackages.ghc.name
    else "ghc${compiler}";

  # The base package set we are going to override:
  packageSet = pkgs_.haskell.packages."${compilerName}";

  # The Haskell package environment after performing overrides:
  haskell = packageSet.override (orig: {
    overrides = pkgs_.lib.composeExtensions
                 (orig.overrides or (_: _: {}))
                 (overrides hlib);
  });

  # The output of cabal2nix;
  cabalNix = cabal:
    import ./nix/cabal2nix.nix {
      inherit cabal flags;
      pkgs = pkgs_;
    };

  # The actual derivation for the package:
  drvSansAdditions = cabalFile: haskell:
    lib.addDataFiles haskell addDataFiles
      (lib.addPostPatch postPatch (
        lib.benchmark
          (lib.appendBuildInputs buildInputs
            (lib.overrideSrc (dirOf (toString cabalFile))
            (haskell.callPackage (toString (cabalNix cabalFile)) {
              mkDerivation = args: haskell.mkDerivation (args //
              (if enableFullyStaticExecutables then lib.makeStatic else {}));
            })))));

  # When we have a single cabal file:
  singlePackage = file:
    let drv = drvSansAdditions file haskell;
    in drv.overrideAttrs (_orig: {
        passthru = _orig.passthru or {} // {
          # Expose static binaries if requested:
          bin = hlib.justStaticExecutables drv;
          interactive = import ./nix/interactive.nix {
            inherit haskell buildInputs;
            packages = [drv];
          };
        };
    });

  # When we have more than one cabal file:
  multiPackage = fileSet: with pkgs_.lib;
  let # fileSet is a attr set where the keys are names of packages and
      # the values are paths to cabal files.  Step one is to turn
      # those keys into actual derivations.
      packages = haskell: mapAttrs
        (_: val: drvSansAdditions val haskell)
        fileSet;
      # We also need a Haskell environment where all of those packages
      # are listed so they can refer to one another.
      haskellExtra = haskell.override (orig: {
        overrides = composeExtensions
          (orig.overrides or (_: _: {}))
          (self: _: packages self);
      });
      # Then build an interactive environment that includes all of
      # those packages and their dependencies.
      interactive =
        import ./nix/interactive.nix {
          inherit buildInputs;
          haskell = haskellExtra;
          packages = attrValues (packages haskellExtra);
        };
    in packages haskellExtra // {
      inherit interactive;
    };

in
  if builtins.isAttrs cabal then multiPackage cabal
  else singlePackage cabal
