# Release History

## [?.?] - Unreleased

  * Link the cabal file inside the cabal2nix build to resolve #5

## [2.0] - 2020-06-07

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

## [1.0] - 2019-09-12

  * Initial release
