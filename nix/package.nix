# ###############################################################################
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
{ basepkgs, sources }:

{
# Path to one or more Cabal files.  May be a single path or an attr
# set of package names and paths to cabal files:
cabal,

# Cabal `-f' flags to use:
flags ? [ ],

# Optional: Override `haskellPackages' with a function.  The
# function takes three arguments and returns a new package set.
#
# The arguments are:
#
# 1. `pkgs.haskell.lib` with some additions.
# 2. `self`: The package set you are currently building.
# 3. `super`: The existing Haskell package set.
overrides ? (lib: self: super: { }),

# Extra nixpkgs packages that your Haskell package depend on:
buildInputs ? [ ],

# Shell fragment to run after the `patchPhase':
postPatch ? "",

# Whether or not to build completely static executables.
#
# Very experimental.  Often broken.  See:
# https://github.com/nh2/static-haskell-nix
enableFullyStaticExecutables ? false,

# Extra build dependencies needed when using
# `enableFullyStaticExecutables`.  This is a function that takes the
# final package set from static-haskell-nix and should return a list
# of packages.
staticBuildInputs ? (_: [ ]),

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
compiler ? "default" }:

let
  # Helper functions for various compiler features.
  compilers = import ./compilers.nix { pkgs = basepkgs; };

  # Some library functions:
  helpers = pkgs: import ./lib.nix { inherit pkgs; };

  # Create a derivation for the given cabal file.
  singlePackage = cabalFile: pkgs:
    let
      haskell = pkgs.haskell.packages.${compilers.name compiler};
      lib = helpers pkgs;
      cabalNix = cabal:
        import ./cabal2nix.nix {
          inherit cabal flags;
          pkgs = basepkgs;
        };
      drv = lib.addDataFiles haskell addDataFiles (lib.addPostPatch postPatch
        (lib.benchmark (lib.appendBuildInputs buildInputs
          (lib.overrideSrc (dirOf (toString cabalFile))
            (haskell.callPackage (toString (cabalNix cabalFile)) { })))));
    in drv.overrideAttrs (orig: {
      passthru = orig.passthru or { } // {
        bin = pkgs.haskell.lib.justStaticExecutables drv;
      };
    });

  # When we have more than one cabal file so we build an attribute set
  # of derivations where the keys are package names and the values are
  # the Haskell derivations.
  multiPackage = fileSet: pkgs:
    pkgs.lib.mapAttrs (_: cabalFile: singlePackage cabalFile pkgs) fileSet;

  # A nixpkgs overlay that updates Haskell packages according to the
  # requested overrides.
  makeOverlay = let
    # Modified version of the nixpkgs Haskell lib:
    hlib = pkgs:
      pkgs.haskell.lib // {
        inherit pkgs;
        inherit (helpers pkgs) unBreak addPostPatch;
        compilerName = compilers.name compiler;
      };
  in overrideFunc: self: super: {
    haskell = super.haskell // {
      packages = super.haskell.packages // {
        ${compilers.name compiler} =
          super.haskell.packages.${compilers.name compiler}.override (orig: {
            overrides =
              super.lib.composeExtensions (orig.overrides or (_: _: { }))
              (overrideFunc (hlib super));
          });
      };
    };
  };

  # Extract the name of a package given a path to its cabal file:
  packageName = cabalFile:
    basepkgs.lib.removeSuffix ".cabal" (baseNameOf (toString cabalFile));

  # Build the final nixpkgs set after applying all necessary
  # overrides.  Returns a attribute set with two keys:
  #
  #   pkgs: The final nixpkgs set.
  #
  #   hask: Either the name of the Haskell package we are building, or
  #         a list of names in the case that we're building more than
  #         one package.
  finalpkgs = pkgs:
    if builtins.isAttrs cabal then {
      pkgs = pkgs.appendOverlays [
        (makeOverlay overrides)
        (self: super: makeOverlay (_: _: _: multiPackage cabal self) self super)
      ];
      hask = builtins.attrNames cabal;
    } else {
      pkgs = pkgs.appendOverlays [
        (makeOverlay overrides)
        (self: super:
          makeOverlay
          (_: _: _: { ${packageName cabal} = singlePackage cabal self; }) self
          super)
      ];
      hask = packageName cabal;
    };

  # Extract one or more Haskell packages from the given package set.
  #
  # If name is a string, extract the named package and add an
  # interactive environment to it.
  #
  # If name is a list of strings, extract all packages as an attribute
  # set and add an interactive environment to the attribute set itself.
  extractPackages = pkgs: haskell: nameOrNames:
    let
      patch = drv: addStaticDeps (makeInteractive drv);
      addStaticDeps = drv:
        if enableFullyStaticExecutables then
          (helpers pkgs).appendBuildInputs (staticBuildInputs pkgs) drv
        else
          drv;
      makeInteractive = drv:
        import ./interactive.nix {
          inherit drv buildInputs;
          pkgs = basepkgs;
          compilerName = compilers.name compiler;
        };
    in if builtins.isList nameOrNames then
      makeInteractive (builtins.listToAttrs (map (name: {
        inherit name;
        value = patch haskell.${name};
      }) nameOrNames))
    else
      patch haskell.${nameOrNames};

  # Using the correct package set, return the resulting derivation(s).
in if enableFullyStaticExecutables then
  let
    patches = basepkgs.callPackage ./patches.nix { };
    basepkgs-patched = patches.patchNixpkgs basepkgs.path;
    result = finalpkgs
      (import basepkgs-patched { inherit (basepkgs) config overlays; });
    static = import "${sources.static-haskell-nix}/survey" {
      normalPkgs = result.pkgs;
      compiler = compilers.name compiler;
      # FIXME: Can we get this from nixpkgs somehow?
      defaultCabalPackageVersionComingWithGhc =
        compilers.attrs.${compilers.name compiler}.cabal;
    };
  in extractPackages static.pkgs static.haskellPackages result.hask
else
  let result = finalpkgs basepkgs;
  in extractPackages result.pkgs
  result.pkgs.haskell.packages.${compilers.name compiler} result.hask
