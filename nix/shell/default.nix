{ sources ? import ../sources.nix
, pkgs ? import sources.nixpkgs { }
, compiler ? "default"
, name ? "nix-hs"
}:
let
  overrideHaskellPackages = overrides:
    pkgs.haskell.packages.${tools.compilerName}.override
      (orig: {
        overrides =
          pkgs.lib.composeExtensions
            (orig.overrides or (_: _: { }))
            overrides;
      });

  unsupportedGHC = tool:
    pkgs.writeShellScriptBin tool ''
      echo >&2  "${tool} does not support the current version of GHC"
      exit 1
    '';

  callPackage = pkgs.lib.callPackageWith tools;

  nix-hs-lib = import ../lib.nix { inherit pkgs; };

  tools = rec {
    inherit (pkgs) lib fetchFromGitHub;
    inherit sources pkgs overrideHaskellPackages unsupportedGHC;
    inherit (nix-hs-lib) unBreak;

    compilers = callPackage ../compilers.nix { };
    compilerName = compilers.name compiler;

    haskell = pkgs.haskell;
    haskellPackages = haskell.packages.${compilerName};
    justStaticExecutables = haskell.lib.justStaticExecutables;
    callCabal2nix = haskellPackages.callCabal2nix;
    callHackage = haskellPackages.callHackage;
    dontCheck = haskell.lib.dontCheck;
    doJailbreak = haskell.lib.doJailbreak;

    cabal-fmt = callPackage ./cabal-fmt.nix { };
    ghcide = callPackage ./ghcide.nix { };
    ormolu = callPackage ./ormolu.nix { };
    stan = callPackage ./stan.nix { };
  };

in
pkgs.mkShell {
  name = "shell-env-for-${name}-${tools.compilerName}";

  buildInputs =
    (with pkgs; [
      stack
    ])
    ++ (with tools; [
      cabal-fmt
      ghcide
      ormolu
      stan
    ])
    ++ (with pkgs.haskell.packages.${tools.compilerName}; [
      cabal-install
      ghc
      hasktags
      hlint
      hoogle
    ]);
}
