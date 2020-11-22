{ sources
, haskellPackages
, justStaticExecutables
}:
let

  cabal-fmt = haskellPackages.callCabal2nix "cabal-fmt" sources.cabal-fmt {
    Cabal = haskellPackages.Cabal_3_2_0_0;
  };

in
justStaticExecutables cabal-fmt
