# Release History

## 21.05 (Unreleased)

  * The deprecated `enableFullyStaticExecutables` argument was removed
    along with direct support for `static-haskell.nix`.

  * The standalone shell file has been renamed from
    `nix/shell/default.nix` to `shell/default.nix`.

  * Removed `ghcide` from the interactive shell environment since it's
    been subsumed by `haskell-language-server`.

  * When generating a derivation for a Haskell package the list of
    source code files will run through a sensible filter which removes
    directories like `dist-newstyle`.

    This prevents the dreaded `dumping very large path (> 256 MiB)`
    warning.

  * Added another test package to demonstrate the `overrides` function
    in `test/overrides/default.nix`.

## 20.09 (November 22, 2020)

  * Update nixpkgs to pull in GHC 8.8.4 and 8.10.2.

  * Add [haskell-language-server](https://github.com/haskell/haskell-language-server)

  * Add [stan](https://github.com/kowainik/stan)

  * Use `callCabal2nixWithOptions` instead of a custom solution (#5)

  * The standalone shell file has been renamed from `nix/shell.nix` to
    `nix/shell/default.nix` and all of the interactive tool files have
    been moved into `nix/shell`.

  * Interactive tools such as `ghcide` and `ormolu` are built from a
    pinned version of nixpkgs.  Everything else, including GHC and
    packages, are built from the nixpkgs passed to nix-hs.

  * Releases will now track NixOS

  * NOTE: the `enableFullyStaticExecutables` flag is deprecated and
    will be removed in the next release.  It can easily be replaced by
    giving nix-hs a package set from `static-haskell.nix`.

## 2.0 (June 7, 2020)

  * Automatically build the latest versions of `ghcide` and `ormolu`
    instead of using the ones in `pkgs.haskellPackages`.

  * Added [cabal-fmt](https://github.com/phadej/cabal-fmt) to the list
    of interactive development tools.

  * Added files for `nix-shell` that can be used with `direnv` to load
    all interactive development tools into `PATH`.  Useful when you
    are working on a project that does not use `nix-hs` but you want
    to easily use the tools it builds for you.

    To use one of these files put this line in an `.envrc` file:

    ```sh
    use nix /path/to/nix-hs/nix/shell.nix
    ```

  * Build fully static binaries (via [static-haskell-nix][]) by
    setting `enableFullyStaticExecutables` to `true`.

  * Created a binary cache via Cachix to store dynamically and
    statically linked compilers and tools.

  * Added tests and configured GitHub actions

[static-haskell-nix]: https://github.com/nh2/static-haskell-nix

## 1.0 (September 12, 2019)

  * Initial release
