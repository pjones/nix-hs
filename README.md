# Haskell + nixpkgs = nix-hs

[![dynamic-linking](https://github.com/pjones/nix-hs/workflows/dynamic-linking/badge.svg)](https://github.com/pjones/nix-hs/actions?query=workflow%3Adynamic-linking)
[![static-linking](https://github.com/pjones/nix-hs/workflows/static-linking/badge.svg)](https://github.com/pjones/nix-hs/actions?query=workflow%3Astatic-linking)
[![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/pjones/nix-hs?label=release)](https://github.com/pjones/nix-hs/releases)
[![cachix](https://img.shields.io/badge/cachix-nix--hs-green)](https://app.cachix.org/cache/nix-hs)

A thin layer over the existing [Haskell][] infrastructure in
[nixpkgs][] which adds all of the tools needed for interactive
development.  Here are some of the features that you might find the
most useful:

  * An interactive development environment (via `nix-shell`) that
    includes:

      * GHC (8.6.5, 8.8.4, or 8.10.2)

      * `cabal`

      * `stack`

      * [`ghcide`][ghcide] version 0.4.0

      * [`ormolu`][ormolu] version 0.1.2.0

      * [`cabal-fmt`][cabal-fmt] version 0.1.4

      * [`stan`][stan] version 0.0.1.0

      * and a Hoogle database for all of your project's dependencies

  * Easy to use system for [overriding Haskell packages](#using-a-broken-package) (e.g., use
    a package not on Hackage, fix a package marked as broken, etc.)
    without having to write tons of Nix code.

  * Works seamlessly with [direnv][], [lorri][], and [niv][] if you
    already have those tools installed.

  * Switch GHC versions by passing an argument to `nix-build` or
    `nix-shell`.

  * [Strip dependencies](#access-to-binary-only-packages) from a package so you can deploy just a
    binary without tons of other packages coming along for the ride.

  * Build [fully static binaries](#fully-static-binaries) that don't require any system
    libraries or the nix store (Linux only).

  * Create an interactive development environment [without adding
    nix-hs](#interactive-environments-without-nix-hs) as a project dependency.

  * Fetch pre-built tools from [the binary cache](#using-the-binary-cache).

## Geting Started

Create a `default.nix` file that looks something like this:

```nix
{ pkgs ? import <nixpkgs> {}
}:

let
  nix-hs =
    import (fetchGit "https://github.com/pjones/nix-hs.git") { inherit pkgs; };

in nix-hs {
  cabal = ./test/hello-world/hello-world.cabal;
}
```

And a `shell.nix` that looks like this:

```nix
# Load an interactive environment:
(import ./. {}).interactive
```

That's it!  Now `nix-build` and `nix-shell` just work!

## Configuration

In addition to the `cabal` argument to the `nix-hs` function, there
are other ways to control how your package is built.

### Enable Flags from the Cabal File

If you have a flag defined in your package's cabal file you can enable
it using the `flags` argument:

```nix
nix-hs {
  cabal = ./mypackage.cabal;
  flags = [ "someflagname" ];
}
```

### Using a Broken Package

If one of your package's dependencies can't be built you can try
overriding it:

```nix
nix-hs {
  cabal = ./mypackage.cabal;

  overrides = lib: self: super: with lib; {
    pipes-text = unBreak (dontCheck (doJailbreak super.pipes-text));
  };
}
```

In the example above, the `overrides` function takes three arguments:

  1. `lib`: An attribute set of library functions.  These are the
     functions provided by the `pkgs.haskellPackages.lib` set plus a
     few more that you might find useful such as:

     - `unBreak`: Remove the `broken` flag from a package
     - `compilerName`: The nixpkgs name of the Haskell compiler
       being used (e.g. `ghc884`)
     - `pkgs`: The full package set, after overriding

  2. `self`: The final set of Haskell packages after applying all
     overrides.  This refers to the future version of the package set
     so if you're not careful you can fall into infinite recursion.
     When in doubt use `super` instead.

  3. `super`: The set of Haskell packages that are being modified.
     Use this attribute set to refer to existing Haskell packages.
     You can also use `super` to access useful functions such as
     `callCabal2nix` and `callHackageDirect`.

The `overrides` function should return an attribute set of Haskell
packages.  The set of returned packages will be merged into the final
set used to build your package.

### Working with Multi-Package Cabal Projects

If you have a project that contains multiple Cabal packages you can
build them all with a single `default.nix`.  The `cabal` argument to
`nix-hs` can either be a path to a Cabal file *or* an attribute set of
Cabal files:

```nix
nix-hs {
  cabal = {
    package1 = ./package1/package1.cabal;
    package2 = ./package1/package2.cabal;
  };
}
```
## Integrating Your Text Editor and Shell

The best way to let your text editor and shell use the environment
created from Nix is to use [direnv][].  Here's an example `.envrc`
file:

```sh
# Use lorri if it's installed, otherwise load shell.nix:
if has lorri; then
  eval "$(lorri direnv)"
else
  use nix
fi

# Reload if these files change:
watch_file $(find . -name '*.cabal' -o -name '*.nix')
```

**NOTE:** Make sure you have a `shell.nix` file that exposes the
`interactive` attribute of the derivation, like the example above.

## Interactive Environments Without nix-hs

If you don't want to use `nix-hs` to control your `default.nix` you
can still use it for building an interactive development environment.
Just clone this repository and use the `nix/shell/default.nix` file.

For example, to drop into an interactive shell:

```
$ nix-shell /path/to/nix-hs/nix/shell
```

Or

```
$ nix-shell --argstr compiler 8.8.3 /path/to/nix-hs/nix/shell
```

Even better, use [direnv][] so your normal shell and text editor can
see all the installed development tools.  Here's an example `.envrc`
file:

```sh
use nix /path/to/nix-hs/nix/shell
```

## Access to Binary-Only Packages

The derivation generated by the `nix-hs` function makes it easy to
access a "binary only" derivation.  This is perfect for deployments or
Docker containers where you don't want to bring along all of your
package's dependencies (including GHC).

The `bin` attribute of the derivation gives you access to this binary
only derivation.  For example, to create a docker container put the
following in `docker.nix`:

```nix
{ pkgs ? import <nixpkgs> { }
}:

let
  mypackage = (import ./. { inherit pkgs; }).bin;

in pkgs.dockerTools.buildImage {
  name = "mypackage";
  tag  = "latest";

  config = {
    Cmd = [ "${mypackage}/bin/hello" ];
  };
}
```

## Fully Static Binaries

It's possible to build fully static binaries using the
[static-haskell-nix][] project.  Here are some things you should keep
in mind:

  * Every upstream dependency needs to be rebuilt so it links with
    [musl][] instead of [glibc][], including GHC and its dependencies.
    This can take a very long time so you might want to consider using
    [the binary cache](#using-the-binary-cache).

  * Ensuring that all packages in nixpkgs build with [musl][] is not a
    priority and is sometimes broken.  You'll often need to pin
    nixpkgs to a specific commit off master.  The best way to find a
    working commit ID for nixpkgs is to see what's being used to build
    the `survey` portion of [static-haskell-nix][].

  * As of June 5, 2020 [a patch](https://github.com/NixOS/nixpkgs/issues/85924)
    needs to be applied to nixpkgs so that we can bootstrap a
    statically compiled GHC.  `nix-hs` will automatically apply this
    patch to the nixpkgs set that you give it.

With that out of the way, let's talk about how to actually build a
static binary.  Most of the work has already been done for you and
it's likely that all you'll need to do is set the
`enableFullyStaticExecutables` argument to `true` when calling the
`nix-hs` function.

You may also need to link with static libraries created by the
[static-haskell-nix][] project.  If your package fails to build due to
missing static libraries use the `staticBuildInputs` argument to
`nix-hs` to add more `buildInputs`.

Here's a complete example:

```nix
{ pkgs ? import <nixpkgs> { } }:

let
  nix-hs =
    import (fetchGit "https://github.com/pjones/nix-hs.git") { inherit pkgs; };

in nix-hs {
  cabal = ./test/hello-world/hello-world.cabal;
  enableFullyStaticExecutables = true;
  staticBuildInputs = static: with static; [ zlib_both ];
}
```

## Using the Binary Cache

If you don't want to spend all day compiling the tools needed to build
your Haskell package and its development environment you can use the
`nix-hs` cache [on Cachix](https://app.cachix.org/cache/nix-hs).

The cache is populated after each `git push` via a [GitHub
action](https://github.com/pjones/nix-hs/actions) and even includes
the statically compiled versions of GHC needed for building [fully
static binaries](#fully-static-binaries).

[haskell]: https://www.haskell.org/
[nixpkgs]: https://nixos.org/nix/
[direnv]: https://github.com/direnv/direnv
[lorri]: https://github.com/target/lorri
[niv]: https://github.com/nmattia/niv
[musl]: https://www.musl-libc.org/
[glibc]: https://www.gnu.org/software/libc/
[static-haskell-nix]: https://github.com/nh2/static-haskell-nix
[ghcide]: https://github.com/haskell/ghcide/
[ormolu]: https://github.com/tweag/ormolu
[stan]: https://github.com/kowainik/stan
[cabal-fmt]: https://github.com/phadej/cabal-fmt
