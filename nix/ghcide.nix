{ sources ? import ./sources.nix
, pkgs ? import sources.nixpkgs { config = { allowBroken = true; }; }
, compilerName ? (import ./compilers.nix { inherit pkgs; }).name "default"
}:
let
  # Haskell overrides to build latest ghcide:
  overrides = self: super: with pkgs.haskell.lib; {
    hie-bios =
      let src = pkgs.fetchFromGitHub {
        owner = "mpickering";
        repo = "hie-bios";
        rev = "20e0e1c2f4d1243aa3024e95cc290041a4b77325"; # Untagged 0.7.1
        name = "hie-bios";
        sha256 = "0z0v4vwfcriqz0fkcc64vxjfbvky7qdxvw07288cq6lfxn69s361";
      };
      in
      dontCheck (super.callCabal2nix "hie-bios" src { });

    haskell-lsp =
      super.callHackage "haskell-lsp" "0.22.0.0" { };

    haskell-lsp-types =
      super.callHackage "haskell-lsp-types" "0.22.0.0" { };

    implicit-hie-cradle =
      let src = pkgs.fetchFromGitHub {
        owner = "Avi-D-coder";
        repo = "implicit-hie-cradle";
        rev = "0.2.0.0";
        name = "implicit-hie-cradle";
        sha256 = "1gv9diz74p73v2infw2zkmfcl9wmpdglpiisp3fakckghkw74z0v";
      };
      in dontCheck (super.callCabal2nix "implicit-hie-cradle" src { });

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
