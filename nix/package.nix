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
  cabal
, # Cabal `-f' flags to use:
  flags ? [ ]
, # Optional: Override `haskellPackages' with a function.  The
  # function takes three arguments and returns a new package set.
  #
  # The arguments are:
  #
  # 1. `pkgs.haskell.lib` with some additions.
  # 2. `self`: The package set you are currently building.
  # 3. `super`: The existing Haskell package set.
  overrides ? (lib: self: super: { })
, # Extra nixpkgs packages that your Haskell package depend on:
  buildInputs ? [ ]
, # Shell fragment to run after the `patchPhase':
  postPatch ? ""
, # If not null, it should be a function that takes a path to the data
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
  addDataFiles ? null
, # A nixpkgs version string for GHC, or "default":
  compiler ? "default"
}:
let
  # Helper functions for various compiler features.
  compilers = import ./compilers.nix { pkgs = basepkgs; };

  # Some library functions:
  helpers = pkgs: import ./lib.nix { inherit pkgs; };

  # A function for building overlays:
  makeOverlay = import ./make-overlay.nix {
    compilerName = compilers.name compiler;
  };

  # Create a derivation for the given cabal file.
  singlePackage = cabalFile: pkgs:
    import ./make-haskell-package.nix {
      inherit pkgs flags postPatch addDataFiles buildInputs;
      cabal = cabalFile;
      hlib = helpers pkgs;
      compilerName = compilers.name compiler;
    };

  # When we have more than one cabal file so we build an attribute set
  # of derivations where the keys are package names and the values are
  # the Haskell derivations.
  multiPackage = fileSet: pkgs:
    pkgs.lib.mapAttrs (_: cabalFile: singlePackage cabalFile pkgs) fileSet;

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
    # This function composes all of the Haskell package overlays
    # then yields the new package set to a final Haskell overlay
    # function.
    let appendHaskellOverrides = overlay:
      pkgs.appendOverlays [
        (makeOverlay (hlib:
          (pkgs.lib.composeExtensions
            (overrides hlib)
            (overlay hlib))))
      ];
    in
    if builtins.isAttrs cabal then {
      pkgs = appendHaskellOverrides (hlib: _: _: multiPackage cabal hlib.pkgs);
      hask = builtins.attrNames cabal;
    } else {
      pkgs = appendHaskellOverrides (hlib: _: _: {
        ${packageName cabal} = singlePackage cabal hlib.pkgs;
      });
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
      patch = drv: addPassthruBinds (makeInteractive drv);
      addPassthruBinds = drv:
        drv.overrideAttrs (orig: {
          passthru = orig.passthru or { } // {
            bin = pkgs.haskell.lib.justStaticExecutables drv;
          };
        });
      makeInteractive = drv:
        import ./interactive.nix {
          inherit drv buildInputs;
          pkgs = basepkgs;
          compilerName = compilers.name compiler;
        };
    in
    if builtins.isList nameOrNames then
      makeInteractive
        (builtins.listToAttrs (map
          (name: {
            inherit name;
            value = patch haskell.${name};
          })
          nameOrNames))
    else
      patch haskell.${nameOrNames};

  result = finalpkgs basepkgs;
in
extractPackages result.pkgs
  result.pkgs.haskell.packages.${compilers.name compiler}
  result.hask
