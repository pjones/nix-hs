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
{ pkgs ? import <nixpkgs> { }, sources ? import ./nix/sources.nix }:

import ./nix/package.nix {
  inherit sources;
  basepkgs = pkgs;
}
