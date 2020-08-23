# Apply patches.
# Stolen from: https://github.com/PostgREST/postgrest/blob/24064f86265b54701fa3c508099e211fb52b0887/nix/patches/default.nix
{ runCommand }: rec {
  applyPatches = name: src: patches:
    runCommand name { inherit src patches; } ''
      set -eou pipefail
      cp -r $src $out
      chmod -R u+w $out
      for patch in $patches; do
        echo "Applying patch $patch"
        patch -d "$out" -p1 < "$patch"
      done
    '';

  # Patch nixpkgs.  Give this function a path.
  patchNixpkgs = nixpkgs:
    applyPatches "nixpkgs" nixpkgs [
      # Fri Jun  5 14:56:18 MST 2020
      # Patch is required for static builds on GHC 8.8.4, see:
      # https://github.com/NixOS/nixpkgs/issues/85924
      # https://github.com/nh2/static-haskell-nix/issues/99
      ../patches/nixpkgs-ghc865-ncurses6.patch
    ];
}
