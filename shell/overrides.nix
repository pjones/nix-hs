################################################################################
#
# This file is part of the package nix-hs. It is subject to the license
# terms in the LICENSE file found in the top-level directory of this
# distribution and at:
#
#   https://code.devalot.com/open/nix-hs
#
# No part of this package, including this file, may be copied, modified,
# propagated, or distributed except according to the terms contained in
# the LICENSE file.
#
{ nix-hs
, lib
, fetchFromGitHub
}:
let
  inherit (nix-hs.haskell)
    appendPatch
    dontCheck
    doJailbreak;

in
self: super: {

  # Nothing to see here.

} // lib.optionalAttrs (lib.hasPrefix "ghc9" nix-hs.ghc.attrName) {
  # Packages that work fine with GHC 9.0.1:
  cryptohash-md5 = doJailbreak super.cryptohash-md5;
  cryptohash-sha1 = doJailbreak super.cryptohash-sha1;

  # https://github.com/haskell-hvr/text-short/issues/20
  text-short = dontCheck super.text-short;

  # https://github.com/Soostone/retry/issues/71
  retry = dontCheck super.retry;

  # https://github.com/snoyberg/mono-traversable/issues/192
  mono-traversable = dontCheck super.mono-traversable;

  # Packages that have specific versions for GHC 9.0.1:
  cryptonite = super.cryptonite_0_29;
  ghc-lib-parser = super.ghc-lib-parser_9_0_1_20210324;
  memory = super.memory_0_16_0;

  # No released version supports Cabal 3.4 or GHC 9.0.1, but the
  # latest commit does have support if you jailbreak it.
  # https://github.com/phadej/cabal-fmt/pull/32
  cabal-fmt =
    let
      src = fetchFromGitHub {
        owner = "phadej";
        repo = "cabal-fmt";
        rev = "a7ef55eaf5db2f9a623e7db39ad9bc38e7bc138f";
        sha256 = "1br6kzybldwgcj35g6fjicz30srbm5gfzajmz6pws4abrp76v8kl";
      };
      drv = super.callCabal2nix "cabal-fmt" src { };
    in
    doJailbreak drv;

  # Needs patch from pending PR to build with GHC 9.0.1:
  # https://github.com/lspitzner/czipwith/pull/2
  czipwith =
    let
      patch = builtins.fetchurl {
        url = "https://patch-diff.githubusercontent.com/raw/lspitzner/czipwith/pull/2.diff";
        sha256 = "101yq4j4q5lph7ra9acq2xm2irxr4kpf0q0vjkmby762xq4a74lc";
      };
    in
    appendPatch super.czipwith patch;

  # No support yet :(

  # There are some patches in the repo, but test's aren't passing.
  haskell-language-server =
    nix-hs.ghc.unsupported "haskell-language-server";

  # Ormolu needs to support ghc-lib-parser_9_0_1_20210324
  # https://github.com/tweag/ormolu/issues/688
  ormolu =
    nix-hs.ghc.unsupported "ormolu";

  # Stan and some of its dependencies are broken on GHC 9.0.1:
  stan =
    nix-hs.ghc.unsupported "stan";
}
