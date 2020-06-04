{ sources ? import ./sources.nix
, pkgs ? import sources.nixpkgs { config = { allowBroken = true; }; }, ghc }:

let
  # Haskell overrides to build latest ghcide:
  overrides = self: super:
    with pkgs.haskell.lib; {
      hie-bios = dontCheck (self.callCabal2nix "hie-bios" sources.hie-bios { });
      haskell-lsp = self.callCabal2nix "haskell-lsp" sources.haskell-lsp { };
      haskell-lsp-types = self.callCabal2nix "haskell-lsp-types"
        "${sources.haskell-lsp}/haskell-lsp-types" { };
      lsp-test = dontCheck (self.callCabal2nix "lsp-test" sources.lsp-test { });
      ghc-check =
        self.callCabal2nix "ghc-check" sources."ghc-check-0.3.0.1" { };
      ghcide = justStaticExecutables (dontCheck
        (doJailbreak (self.callCabal2nix "ghcide" sources.ghcide { })));
    };

  # Perform the overrides:
  haskell = pkgs.haskell.packages."${ghc}".override (orig: {
    overrides =
      pkgs.lib.composeExtensions (orig.overrides or (_: _: { })) overrides;
  });

  # The package!
in haskell.ghcide
