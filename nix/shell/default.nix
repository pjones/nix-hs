{ compiler ? "default"
, name ? "nix-hs"
}:
let
  sources = import ../sources.nix;
  pkgs = import sources.nixpkgs { };

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
    inherit (pkgs) lib fetchurl fetchFromGitHub;
    inherit sources pkgs overrideHaskellPackages unsupportedGHC;
    inherit (nix-hs-lib) unBreak;

    compilers = callPackage ../compilers.nix { };
    compilerName = compilers.name compiler;

    haskell = pkgs.haskell;
    haskellPackages = haskell.packages.${compilerName};
    overrides = callPackage ./overrides.nix { };

    justStaticExecutables = haskell.lib.justStaticExecutables;
    dontCheck = haskell.lib.dontCheck;
    doJailbreak = haskell.lib.doJailbreak;

    cabal-fmt = callPackage ./cabal-fmt.nix { };
    haskell-language-server = callPackage ./haskell-language-server.nix { };
    hlint = justStaticExecutables overrides.hlint;
    ormolu = callPackage ./ormolu.nix { };
    stan = callPackage ./stan.nix { };
    stack = justStaticExecutables overrides.stack;
  };

in
assert (pkgs.lib.assertMsg
  (pkgs.haskell.packages ? ${tools.compilerName})
  "This version of nix-hs does not support ${tools.compilerName}.");

pkgs.mkShell {
  name = "shell-env-for-${name}-${tools.compilerName}";

  buildInputs =
    (with tools; [
      cabal-fmt
      haskell-language-server
      hlint
      ormolu
      stan
      stack
    ])
    ++ (with tools.overrides; [
      cabal-install
      ghc
      hasktags
      hoogle
    ]);
}
