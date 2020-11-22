{ lib
, overrideHaskellPackages
, fetchFromGitHub
, dontCheck
, doJailbreak
, unBreak
, sources
, compilerName
}:

overrideHaskellPackages (self: super: {
  aeson = super.aeson_1_5_2_0;
  brittany = doJailbreak super.brittany;
  data-tree-print = doJailbreak super.data-tree-print;

  fourmolu =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/fourmolu-0.2.0.0/fourmolu-0.2.0.0.tar.gz";
      sha256 = "1dkv9n9m0wrpila8z3fq06p56c7af6avd9kv001s199b0ca7pwa6";
    };
    in
    super.callCabal2nix "fourmolu" src { };

  hie-bios = dontCheck super.hie-bios_0_7_1;

  hie-compat =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/hie-compat-0.1.0.0/hie-compat-0.1.0.0.tar.gz";
      sha256 = "1q6rrppd0vb5svk36vkqaizq0gggk8cvn3gp245v8l9vcbbphj1p";
    };
    in
    super.callCabal2nix "hie-compat" src { };

  haskell-language-server =
    dontCheck
      (super.callCabal2nix "haskell-language-server" sources.haskell-language-server { });

  hls-plugin-api =
    super.callCabal2nix "hls-plugin-api"
      "${sources.haskell-language-server}/hls-plugin-api"
      { };

  hls-hlint-plugin =
    super.callCabal2nix "hls-hlint-plugin"
      "${sources.haskell-language-server}/plugins/hls-hlint-plugin"
      { };

  hls-tactics-plugin =
    super.callCabal2nix "hls-tactics-plugin"
      "${sources.haskell-language-server}/plugins/tactics"
      { };

  hlint = super.callCabal2nix "hlint" sources.hlint { };

  implicit-hie-cradle =
    let src = fetchFromGitHub {
      owner = "Avi-D-coder";
      repo = "implicit-hie-cradle";
      rev = "0.2.0.1";
      name = "implicit-hie-cradle";
      sha256 = "1nbwbifhmx9i3m3bf5m5pi0arvxxdsgdq1aw2l7kssfym4v3fbdl";
    };
    in dontCheck (super.callCabal2nix "implicit-hie-cradle" src { });

  ghc-check = super.callHackage "ghc-check" "0.5.0.1" { };

  ghcide =
    dontCheck
      (doJailbreak
        (super.callCabal2nix "ghcide" sources.ghcide { }));

  ghc-lib-parser =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/ghc-lib-parser-8.10.2.20200916/ghc-lib-parser-8.10.2.20200916.tar.gz";
      sha256 = "1apm9zn484sm6b8flbh6a2kqnv1wjan4l58b81cic5fc1jsqnyjk";
    };
    in super.callCabal2nix "ghc-lib-parser" src { };

  ghc-lib =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/ghc-lib-8.10.2.20200916/ghc-lib-8.10.2.20200916.tar.gz";
      sha256 = "1gx0ijay9chachmd1fbb61md3zlvj24kk63fk3dssx8r9c2yp493";
    };
    in
    super.callCabal2nix "ghc-lib" src { };

  lsp-test =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/lsp-test-0.11.0.7/lsp-test-0.11.0.7.tar.gz";
      sha256 = "160w3a5mmgjwfgmdrv2ahb4j5r9axc0y52limyrps8nb2s0xrqbf";
    };
    in dontCheck (super.callCabal2nix "lsp-test" src { });

  ormolu = super.callCabal2nix "ormolu" sources.ormolu { };

  refinery =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/refinery-0.3.0.0/refinery-0.3.0.0.tar.gz";
      sha256 = "08s5pw6j3ncz96zfc2j0cna2zbf4vy7045d6jpzmq2sa161qnpgi";
    };
    in super.callCabal2nix "refinery" src { };

  retrie = unBreak super.retrie;

  stylish-haskell =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/stylish-haskell-0.12.2.0/stylish-haskell-0.12.2.0.tar.gz";
      sha256 = "1ck8i550rvzbvzrm7dvgir73slai8zmvfppg3n5v4igi7y3jy0mr";
    };
    in
    super.callCabal2nix "stylish-haskell" src { };
} // lib.optionalAttrs (lib.hasPrefix "ghc810" compilerName) {
  apply-refact = super.apply-refact_0_8_0_0;

  # Use a fork of brittany that supports GHC 8.10.2 (via the
  # haskell-language-server cabal.project file).
  brittany =
    let src = fetchFromGitHub {
      owner = "bubba";
      repo = "brittany";
      rev = "c59655f10d5ad295c2481537fc8abf0a297d9d1c";
      name = "brittany";
      sha256 = "1rkk09f8750qykrmkqfqbh44dbx1p8aq1caznxxlw8zqfvx39cxl";
    };
    in dontCheck (super.callCabal2nix "brittany" src { });

  ghc-exactprint = super.ghc-exactprint_0_6_3_2;
})
