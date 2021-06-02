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
{ compiler ? "default"
, name ? "nix-hs"
}:
let
  sources = import ../nix/sources.nix;
  pkgs = import sources.nixpkgs { };
  nix-hs = import ../lib { inherit pkgs compiler; };

  overrides =
    nix-hs.packages.overrideHaskellPackages
      (import ./overrides.nix {
        inherit (pkgs) lib fetchFromGitHub;
        inherit nix-hs;
      })
      (nix-hs.ghc.packages);

  packages = with overrides; [
    cabal-fmt
    cabal-install
    haskell-language-server
    hasktags
    hlint
    hoogle
    ormolu
    stan
  ];

  # A smarter version of `justStaticExecutables` that first checks if
  # the derivation looks like a Haskell package.  Non-Haskell packages
  # are just passed through.
  justBin = drv:
    if drv ? override
    then nix-hs.haskell.justStaticExecutables drv
    else drv;
in
assert (pkgs.lib.assertMsg
  (pkgs.haskell.packages ? ${nix-hs.ghc.attrName})
  "This version of nix-hs does not support ${nix-hs.ghc.attrName}.");

pkgs.mkShell {
  name = "shell-env-for-${name}-${nix-hs.ghc.attrName}";

  buildInputs =
    map justBin packages
    ++ [ overrides.ghc ]
    ++ [ pkgs.stack ];

  passthru = {
    # Allow building individual packages (for testing) via `nix-build -A...`:
    haskell = overrides;
  };
}
