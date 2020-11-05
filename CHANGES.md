# Release History

## 20.09 (November 5, 2020)

  * Update nixpkgs to pull in GHC 8.8.4 and 8.10.2.

  * Update ghcide to version 0.4.0.

  * Update cabal-fmt to version 0.1.4.

  * Add [stan](https://github.com/kowainik/stan) at version 0.0.1.0.

  * Use `callCabal2nixWithOptions` instead of a custom solution (#5)

  * New `haskell-packages-overlay.nix` file so nix-hs can patch broken
    Haskell packages that prevent the tests from passing.

  * The standalone shell file has been renamed from `nix/shell.nix` to
    `nix/shell/default.nix` and all of the interactive tool files have
    been moved into `nix/shell`.

  * Release will now track NixOS

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
