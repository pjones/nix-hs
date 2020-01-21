let
  # Must use a known working version of nixpkgs:
  # https://github.com/nh2/static-haskell-nix
  commit = "2c07921cff84dfb0b9e0f6c2d10ee2bfee6a85ac";
in
{ pkgs ? import (fetchTarball "https://github.com/nh2/nixpkgs/archive/${commit}.tar.gz") {}
}:

let
  nix-hs = import ../default.nix { inherit pkgs; };

in nix-hs {
  cabal = ./test.cabal;
  enableFullyStaticExecutables = true;
}
