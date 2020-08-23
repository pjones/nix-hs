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
{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:

pkgs.mkShell {
  name = "nix-hs";

  NIX_PATH = "nixpkgs=${sources.nixpkgs.url}";

  buildInputs = with pkgs; [
    jq
    cachix
  ];
}
