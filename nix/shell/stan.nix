{ sources
, lib
, overrideHaskellPackages
, fetchFromGitHub
, justStaticExecutables
, doJailbreak
, dontCheck
, unBreak
, unsupportedGHC
, haskellPackages
}:
let
  haskell = overrideHaskellPackages (self: super: {
    extensions =
      let src =
        fetchFromGitHub {
          owner = "kowainik";
          repo = "extensions";
          name = "extensions";
          rev = "4d3b514f5d14b850fc4d0c05ddca3ec75f678174";
          sha256 = "1fjp0hyvsc5pd2wwxnq9vqhwfhhj2jxasyqh4bndlfzd374zj6jg";
        };
      in
      self.callCabal2nix "extensions" src { };

    Cabal = super.Cabal_3_2_0_0;
    microaeson = unBreak (doJailbreak super.microaeson);
    pcg-random = dontCheck super.pcg-random;
    stan = self.callCabal2nix "stan" sources.stan { };
  });
in
if lib.hasPrefix "ghc-8.6" haskellPackages.ghc.name
then unsupportedGHC "stan"
else justStaticExecutables haskell.stan
