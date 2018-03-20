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
{ stdenvNoCC, pkgs, lib
, bash, cabal2nix, haskellPackages
}:

with lib;

let
  drv = stdenvNoCC.mkDerivation rec {
    name = "nix-hs-${version}";
    version = "0.2.0";

    phases = [ "installPhase" ];

    installPhase = ''
      mkdir -p $out/bin $out/templates $out/lib

      export bash=${bash}
      export cabal2nix=${cabal2nix}
      export stack=${haskellPackages.stack}
      export templates=$out/templates
      export interactive=$out/lib/interactive.nix
      export stacknix=$out/lib/stack.nix

      substituteAll ${../src/nix-hs.sh} $out/bin/nix-hs
      chmod 0555 $out/bin/nix-hs

      install -m0444 ${../templates/default.nix} $out/templates/default.nix
      install -m0444 ${../nix/interactive.nix} $out/lib/interactive.nix
      install -m0400 ${../nix/stack.nix} $out/lib/stack.nix
    '';
  };
in {
  callPackage = pkgs.callPackage ./call-package.nix { };
} // drv
