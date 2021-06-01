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
# Details and functions about the version of GHC being used.
{ pkgs
, compiler ? "default"
}:
let
  # A function that can translate a user-entered compiler name by
  # turning it into the correct nixpkgs attribute name for GHC:
  toAttrName = compiler:
    let
      clean = str:
        pkgs.lib.removePrefix "ghc"
          (builtins.replaceStrings [ "." "-" ] [ "" "" ] str);
    in
    if compiler == "default"
    then "ghc${clean pkgs.haskellPackages.ghc.name}"
    else "ghc${clean compiler}";

  # The package set for the selected version of GHC:
  packages = pkgs.haskell.packages.${toAttrName compiler};
in
{
  # Calculate the nixpkgs attribute for a version of GHC:
  inherit toAttrName;

  # The attribute name for the selected version of GHC:
  attrName = toAttrName compiler;

  # The compiler's attribute set from nixpkgs:
  ghc = packages.ghc;

  # The complete package set for the selected version of GHC:
  inherit packages;

  # The compiler's name (e.g., ghc-8.10.4):
  name = packages.ghc.name;

  # The compiler's system name (e.g., x86_64-linux):
  system = packages.ghc.system;

  # A function that generates a derivation where the sole executable
  # just reports that the selected version of GHC isn't supported.
  unsupported = tool:
    pkgs.writeShellScriptBin tool ''
      echo >&2 "${tool} does not support GHC ${packages.ghc.version}"
      exit 1
    '';
}
