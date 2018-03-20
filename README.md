# Haskell + nixpkgs = nix-hs

Are you a [Haskell][] programmer?  Do you use [nixpkgs][]?  Want to
make using those two together really simple?  You're in luck.

This project provides a set of Nix files and a tool called `nix-hs`
that makes working with Haskell projects very simple.  For starters,
Nix files are automatically generated and updated as needed.  Other
features include:

  * Works with both `cabal` and `stack`
  * Build with profiling using a command line option
  * Easily use any version of GHC in `nixpkgs`
  * Interactive development and package generation

## Installing nix-hs

Coming soon...

Hint: Install it as an [overlay] [].

## Interactive Development

Coming soon...

Hint: `$ nix-hs -h`

## Making a Private Package for nixpkgs

Coming soon...

## Other Things You Should Know

  * In order to be idempotent, `nix-hs` runs `cabal` without a
    configuration file (usually `~/.cabal/config`).  This also keeps
    `cabal` from downloading packages from hackage.

[haskell]: https://www.haskell.org/
[nixpkgs]: https://nixos.org/nix/
[overlay]: https://nixos.org/nixpkgs/manual/#chap-overlays
