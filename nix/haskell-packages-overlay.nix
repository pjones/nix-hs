# This is an overlay for Haskell packages.  It is sometimes used to
# override core packages that fail to build.  For example, when a
# broken `streaming-commons` package caused `cabal2nix` to fail.
lib: self: super: with lib; { }
