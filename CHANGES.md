# Release History

## [NEXT] - ????-??-??

  * Automatically build the correct versions of `ghcide` and `ormolu`
    instead of using the ones in `pkgs.haskellPackages`.

  * Added files for `nix-shell` that can be used with `direnv` to load
    all interactive development tools into `PATH`.  Useful when you
    are working on a project that does not use `nix-hs` but you want
    to easily use the tools it builds for you.

    To use one of these files put this line in an `.envrc` file:

    ```sh
    use nix /path/to/nix-hs/shell/shell-ghc865.nix
    ```

  * Build fully static binaries (via [static-haskell-nix][]) by
    setting `enableFullyStaticExecutables` to `true`.

[static-haskell-nix]: https://github.com/nh2/static-haskell-nix

## [1.0] - 2019-09-12

  * Initial release
