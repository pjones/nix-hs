{ pkgs
, cabal
, flags
, compilerName
, hlib
, postPatch
, addDataFiles
, buildInputs
}:
let
  haskell = pkgs.haskell.packages.${compilerName};

  # The package name derived from the cabal file name:
  name = pkgs.lib.removeSuffix ".cabal" (baseNameOf (toString cabal));

  # All flags as a string:
  flagsStr = pkgs.lib.concatMapStringsSep " " (f: "-f${f}") flags;

  # Load the cabal file:
  cabal2nix = haskell.callCabal2nixWithOptions name (dirOf cabal) flagsStr { };

  # The final derivation all patched up:
  drv =
    hlib.addDataFiles haskell addDataFiles
      (hlib.addPostPatch postPatch
        (hlib.benchmark
          (hlib.appendBuildInputs buildInputs cabal2nix)));
in
drv
