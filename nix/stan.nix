{ sources ? import ./sources.nix
, pkgs ? import sources.nixpkgs { config = { allowBroken = true; }; }
, compilerName ? (import ./compilers.nix { inherit pkgs; }).name "default"
}:
let
  haskell = (pkgs.haskellPackages.override (orig: {
    overrides = pkgs.lib.composeExtensions
      (orig.overrides or (_: _: { }))
      (self: super: with pkgs.haskell.lib; {
        microaeson = doJailbreak super.microaeson;

        stan =
          justStaticExecutables
            (super.callCabal2nix "stan" sources.stan { });
      });
  }));
in
haskell.stan
