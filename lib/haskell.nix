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
# Functions for modifying Haskell derivations.
{ pkgs
, ghc
}:
let
  lib = pkgs.lib;

  # A source cleaner for Haskell programs:
  haskellSourceFilter = src:
    lib.cleanSourceWith {
      inherit src;
      filter = name: type:
        let baseName = baseNameOf (toString name); in
        lib.cleanSourceFilter name type &&
        !(
          baseName == "dist"
          || baseName == "dist-newstyle"
          || baseName == "TAGS"
          || lib.hasPrefix "." baseName
        );
    };
in
pkgs.haskell.lib // {

  # Expose the selected compiler's attribute name (e.g., ghc8104):
  compilerName = ghc.attrName;

  # Override a derivation so that its source is smaller:
  cleanSource = src: drv:
    pkgs.haskell.lib.overrideCabal drv (_: {
      src = haskellSourceFilter src;
    });

  # Enable benchmarks (not sure why this isn't the default):
  doBenchmark = drv:
    pkgs.haskell.lib.doBenchmark drv;

  # Missing from Haskell lib:
  unBreak = drv:
    pkgs.haskell.lib.overrideCabal drv (_: {
      broken = false;
      patches = [ ];
    });

  # Append some build inputs:
  appendBuildInputs = buildInputs: drv:
    drv.overrideAttrs
      (orig: { buildInputs = orig.buildInputs ++ buildInputs; });

  # Add more commands to the `postPatch` phase:
  appendPostPatch = text: drv:
    pkgs.haskell.lib.overrideCabal drv (orig: {
      postPatch = ''
        ${orig.postPatch or ""}
        ${text}
      '';
    });

  # Add data files to `drv` by running `f` and giving it the path to
  # where data files will be stored.  It should return a shell
  # fragment.
  appendDataFiles = ghc: f: drv:
    let
      gname = ghc.name;
      gsystem = ghc.system;
      go = pkgs.haskell.lib.overrideCabal drv (orig: {
        postInstall = (orig.postInstall or "")
        + f "$data/share/${gname}/${gsystem}-${gname}/${drv.name}";
      });
    in
    if f != null then go else drv;

  # Append the elements of an attrset to a derivation's `passthru` attribute:
  appendPassthru = attrs: drv:
    drv.overrideAttrs (orig: {
      passthru = (orig.passthru or { }) // attrs;
    });
}
