{ sources ? import ./sources.nix
, pkgs ? import sources.nixpkgs { config = { allowBroken = true; }; }
, compilerName
}:
let
  # Haskell overrides to build latest ghcide:
  overrides = self: super: with pkgs.haskell.lib; {
    hie-bios =
      dontCheck (super.callHackage "hie-bios" "0.6.0" { });

    haskell-lsp =
      super.callHackage "haskell-lsp" "0.22.0.0" { };

    haskell-lsp-types =
      super.callHackage "haskell-lsp-types" "0.22.0.0" { };

    lsp-test =
      dontCheck (super.callHackage "lsp-test" "0.11.0.3" { });

    ghc-check =
      super.callHackage "ghc-check" "0.5.0.1" { };

    ghcide = justStaticExecutables (dontCheck
      (doJailbreak (self.callCabal2nix "ghcide" sources.ghcide { })));
  };

  # Perform the overrides:
  haskell =
    pkgs.haskell.packages.${compilerName}.override
      (orig: {
        overrides =
          pkgs.lib.composeExtensions
            (orig.overrides or (_: _: { }))
            overrides;
      });

in
# The package!
haskell.ghcide
