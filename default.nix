################################################################################
# This file is a nixpkgs overlay.

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

self: super: {
  nix-hs = with self; callPackage ./nix/package.nix { };
}
