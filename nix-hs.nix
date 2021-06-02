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
{ pkgs
}:

{
  # Path to one or more Cabal files.  May be a single path or an attr
  # set of package names and paths to cabal files:
  cabal

  # Cabal `-f' flags to use:
, flags ? [ ]

  # A nixpkgs version string for GHC, or "default":
, compiler ? "default"

  # Optional: Override `haskellPackages' with a function.  The
  # function takes three arguments and returns a new Haskell package
  # set.
  #
  # The arguments are:
  #
  # 1. `pkgs.haskell.lib` with some additions (see below).
  # 2. `self`: The package set you are currently building.
  # 3. `super`: The existing Haskell package set.
  #
  # For a list of additional functions that are available in the `lib`
  # argument, see `lib/haskell.nix`.
  #
  # Also, one additional attribute will be available in `lib`: pkgs,
  # the final nixpkgs set after all Haskell overrides have been
  # applied.  This is important for passing on to other invocations of
  # nix-hs for any dependencies so they pick up the already patched
  # dependencies from this overrides function.
  #
  # An example overrides function can be found in:
  #
  #     test/overrides/default.nix
, overrides ? (lib: self: super: { })

  # Extra nixpkgs packages that your Haskell package depend on:
, buildInputs ? [ ]

  # Shell fragment to run after the `patchPhase':
, postPatch ? ""

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
, addDataFiles ? null
}:
let
  nix-hs = import ./lib { inherit pkgs compiler; };

  # Create a derivation for the given cabal file.
  singlePackage = cabalFile: packages:
    let
      drv =
        nix-hs.packages.derivationFromCabal {
          inherit flags postPatch addDataFiles buildInputs packages;
          cabal = cabalFile;
        };
    in
    nix-hs.haskell.appendPassthru
      {
        bin = nix-hs.haskell.justStaticExecutables drv;
        interactive = makeInteractive packages drv;
      }
      drv;

  # When we have more than one cabal file so we build an attribute set
  # of derivations where the keys are package names and the values are
  # the Haskell derivations.
  multiPackage = fileSet: packages:
    pkgs.lib.mapAttrs
      (_name: cabalFile: singlePackage cabalFile packages)
      fileSet;

  # Returns an attribute set that contains the generated Haskell packages.
  generatedPackages = packages:
    if builtins.isAttrs cabal
    then multiPackage cabal packages
    else { ${nix-hs.packages.nameFromCabal cabal} = singlePackage cabal packages; };

  # Generates an interactive shell environment for the given Haskell
  # derivation (or derivations).
  makeInteractive = packages: drv:
    let
      shellDrv = import ./shell { inherit compiler; };

      # Use the Hoogle package from the interactive shell environment
      # and not the one from the current package set since this is the
      # hoogle binary we want in the interactive shell.  Bonus
      # feature: we automatically pick up any patches that make hoogle
      # work with the selected compiler.
      withPatchedHoogle =
        nix-hs.packages.overrideHaskellPackages
          (_self: _super: { hoogle = shellDrv.haskell.hoogle; })
          packages;

      shellFor = inputs:
        withPatchedHoogle.shellFor {
          packages = _: inputs;
          withHoogle = true;
          doBenchmark = true;
          buildInputs = buildInputs ++ shellDrv.buildInputs;
        };
    in
    if pkgs.lib.isDerivation drv
    then shellFor [ drv ]
    else shellFor (builtins.attrValues drv);

  # Extract the generated Haskell packages out of the final package set.
  extractPackages = packages:
    let
      drvs =
        pkgs.lib.mapAttrs
          (name: _value: packages.${name})
          cabal;
    in
    if builtins.isAttrs cabal
    then { interactive = makeInteractive packages drvs; } // drvs
    else packages.${nix-hs.packages.nameFromCabal cabal};

  # The haskell package set after applying the requested overrides and
  # adding in the package generated from the cabal file(s):
  haskellPackages =
    let
      # Augmented overrides function that accepts the final nixpkgs
      # set for the `pkgs` attribute which is passed in the Haskell
      # library functions attrset.
      overrides_ = self:
        overrides ({
          pkgs = self;
        } // nix-hs.haskell);

      # Jump through some hoops to generate a patched Haskell package
      # set from the given nixpkgs set, passing along the final
      # nixpkgs set to the overriding function.
      packages =
        (nix-hs.packages.overrideHaskellPackagesIn
          overrides_
          pkgs).haskell.packages.${nix-hs.ghc.attrName};
    in
    nix-hs.packages.overrideHaskellPackages
      (_self: _super: generatedPackages packages)
      packages;

in
extractPackages haskellPackages
