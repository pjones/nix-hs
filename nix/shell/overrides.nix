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

  apply-refact =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/apply-refact-0.9.1.0/apply-refact-0.9.1.0.tar.gz";
      sha256 = "0r0ch54pqw7v22hfvj01wsr633q8sd83ig9b77chzrbdvmk9xj6s";
    };
    in super.callCabal2nix "apply-refact" src { };

  brittany =
    doJailbreak (
      let src = fetchTarball {
        url = "https://hackage.haskell.org/package/brittany-0.13.1.0/brittany-0.13.1.0.tar.gz";
        sha256 = "172mg0ch2awfzhz8vzvjrfdjylfzawrbgfr5z82l1qzjh6g9z295";
      };
      in super.callCabal2nix "brittany" src { }
    );

  data-tree-print = doJailbreak super.data-tree-print;

  fourmolu =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/fourmolu-0.3.0.0/fourmolu-0.3.0.0.tar.gz";
      sha256 = "05b8ksifahahha3ra1mjby1gr9ysm5jc8li09v40l36z8n370l28";
    };
    in
    super.callCabal2nix "fourmolu" src { };

  hiedb =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/hiedb-0.3.0.1/hiedb-0.3.0.1.tar.gz";
      sha256 = "0n6m13lybnb6vl0lh69i2v6xykcd0bl5svkk18964k4wza8a5b12";
    };
    in dontCheck (super.callCabal2nix "hiedb" src { });

  hie-bios = dontCheck super.hie-bios_0_7_1;

  hie-compat =
    super.callCabal2nix "hie-compat"
      "${sources.haskell-language-server}/hie-compat"
      { };

  haskell-language-server =
    dontCheck
      (super.callCabal2nix "haskell-language-server" sources.haskell-language-server { });

  hls-plugin-api =
    super.callCabal2nix "hls-plugin-api"
      "${sources.haskell-language-server}/hls-plugin-api"
      { };

  hls-class-plugin =
    super.callCabal2nix "hls-class-plugin"
      "${sources.haskell-language-server}/plugins/hls-class-plugin"
      { };

  hls-eval-plugin =
    super.callCabal2nix "hls-eval-plugin"
      "${sources.haskell-language-server}/plugins/hls-eval-plugin"
      { };

  hls-explicit-imports-plugin =
    super.callCabal2nix "hls-explicit-imports-plugin"
      "${sources.haskell-language-server}/plugins/hls-explicit-imports-plugin"
      { };

  hls-haddock-comments-plugin =
    super.callCabal2nix "hls-haddock-comments-plugin"
      "${sources.haskell-language-server}/plugins/hls-haddock-comments-plugin"
      { };

  hls-hlint-plugin =
    super.callCabal2nix "hls-hlint-plugin"
      "${sources.haskell-language-server}/plugins/hls-hlint-plugin"
      { };

  hls-retrie-plugin =
    super.callCabal2nix "hls-retrie-plugin"
      "${sources.haskell-language-server}/plugins/hls-retrie-plugin"
      { };

  hls-splice-plugin =
    super.callCabal2nix "hls-splice-plugin"
      "${sources.haskell-language-server}/plugins/hls-splice-plugin"
      { };

  hls-tactics-plugin =
    dontCheck (
      super.callCabal2nix "hls-tactics-plugin"
        "${sources.haskell-language-server}/plugins/hls-tactics-plugin"
        { }
    );

  hlint = super.callCabal2nix "hlint" sources.hlint { };

  implicit-hie =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/implicit-hie-0.1.2.5/implicit-hie-0.1.2.5.tar.gz";
      sha256 = "1l0rz4r4hamvmqlb68a7y4s3n73y6xx76zyprksd0pscd9axznnv";
    };
    in super.callCabal2nix "implicit-hie" src { };

  implicit-hie-cradle =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/implicit-hie-cradle-0.3.0.2/implicit-hie-cradle-0.3.0.2.tar.gz";
      sha256 = "1fhc8zccd7g7ixka05cba3cd4qf5jvq1zif29bhn593dfkzy89lz";
    };
    in dontCheck (super.callCabal2nix "implicit-hie-cradle" src { });

  ghc-check = super.callHackage "ghc-check" "0.5.0.1" { };

  ghc-exactprint =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/ghc-exactprint-0.6.4/ghc-exactprint-0.6.4.tar.gz";
      sha256 = "0clxvnl39jkjv3mlfjz1v0bmhy6026vmy5bqcbbqrzabydizvv0k";
    };
    in super.callCabal2nix "ghc-exactprint" src { };

  ghcide =
    dontCheck
      (super.callCabal2nix "ghcide"
        "${sources.haskell-language-server}/ghcide"
        { });

  ghc-lib-parser =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/ghc-lib-parser-8.10.3.20201220/ghc-lib-parser-8.10.3.20201220.tar.gz";
      sha256 = "0ah9wp2m49kpfj7zhi9gs00jwvqcv1n00xdb5l4m6vbmps6dwcsl";
    };
    in super.callCabal2nix "ghc-lib-parser" src { };

  ghc-lib-parser-ex =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/ghc-lib-parser-ex-8.10.0.17/ghc-lib-parser-ex-8.10.0.17.tar.gz";
      sha256 = "1wh0886bdpnfn90h1lbfrpr36jlyy2x4m1mqlwmr01pl5h19xb5z";
    };
    in super.callCabal2nix "ghc-lib-parser-ex" src { };

  ghc-lib =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/ghc-lib-8.10.3.20201220/ghc-lib-8.10.3.20201220.tar.gz";
      sha256 = "1zn1jsl3xdfyiymq9yzhrzwkk8g77bhblbsgahf3w59fpinp43lj";
    };
    in
    super.callCabal2nix "ghc-lib" src { };

  heapsize =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/heapsize-0.3.0.1/heapsize-0.3.0.1.tar.gz";
      sha256 = "0c8lqndpbx9ahjrqyfxjkj0z4yhm1zlcn8al0ir4ldlahql2xv3r";
    };
    in super.callCabal2nix "heapsize" src { };

  megaparsec = super.megaparsec_9_0_0;

  lsp =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/lsp-1.1.1.0/lsp-1.1.1.0.tar.gz";
      sha256 = "0lcqiw5304llxamizza28xy4llhmmrr3dkvlm4pgrhzfcxqwnfrm";
    };
    in super.callCabal2nix "lsp" src { };

  lsp-test =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/lsp-test-0.13.0.0/lsp-test-0.13.0.0.tar.gz";
      sha256 = "1b0p678bh4h1mfbi1v12g9zhnyhgq5q3fiv491ni461v44ypr6bn";
    };
    in dontCheck (super.callCabal2nix "lsp-test" src { });

  lsp-types =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/lsp-types-1.1.0.0/lsp-types-1.1.0.0.tar.gz";
      sha256 = "1l8g7iq9zsq19hxamy37hf61bmld500pha2xcwwqs7hk53k9wgn8";
    };
    in super.callCabal2nix "lsp-types" src { };

  opentelemetry =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/opentelemetry-0.6.1/opentelemetry-0.6.1.tar.gz";
      sha256 = "08k71z7bns0i6r89nmxqsl00kyksicq619rqy6pf5m7hq1r4zs9m";
    };
    in super.callCabal2nix "opentelemetry" src { };

  ormolu = super.callCabal2nix "ormolu" sources.ormolu { };

  refinery =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/refinery-0.3.0.0/refinery-0.3.0.0.tar.gz";
      sha256 = "08s5pw6j3ncz96zfc2j0cna2zbf4vy7045d6jpzmq2sa161qnpgi";
    };
    in super.callCabal2nix "refinery" src { };

  retrie = unBreak super.retrie;

  shake-bench =
    super.callCabal2nix "shake-bench"
      "${sources.haskell-language-server}/shake-bench"
      { };

  stylish-haskell =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/stylish-haskell-0.12.2.0/stylish-haskell-0.12.2.0.tar.gz";
      sha256 = "1ck8i550rvzbvzrm7dvgir73slai8zmvfppg3n5v4igi7y3jy0mr";
    };
    in
    super.callCabal2nix "stylish-haskell" src { };

  uniplate =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/uniplate-1.6.13/uniplate-1.6.13.tar.gz";
      sha256 = "01p79pxmgdq8ya8llwrip5awc521y6qdchqw18ydkkidglv5m3bj";
    };
    in super.callCabal2nix "uniplate" src { };

  unliftio-core =
    let src = fetchTarball {
      url = "https://hackage.haskell.org/package/unliftio-core-0.2.0.1/unliftio-core-0.2.0.1.tar.gz";
      sha256 = "06cbv2yx5a6qj4p1w91q299r0yxv96ms72xmjvkpm9ic06ikvzzq";
    };
    in doJailbreak (super.callCabal2nix "unliftio-core" src { });
})
