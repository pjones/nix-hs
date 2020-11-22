{ pkgs ? import <nixpkgs> { }
}:
let
  nix-hs =
    import
      (fetchTarball
        "https://github.com/pjones/nix-hs/archive/release-20.09.tar.gz")
      {
        inherit pkgs;
      };
in
nix-hs {
  cabal = ./test/hello-world/hello-world.cabal;
}
