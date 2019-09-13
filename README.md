Haskell + nixpkgs = nix-hs
==========================

Are you a [Haskell][] programmer?  Do you use [nixpkgs][]?  Want to
make using those two together really simple?  You're in luck.

This project provides a set of Nix files that makes working with
Haskell projects very simple.  For starters, Nix files are
automatically generated and updated as needed.  Other features
include:

  * Your package will build with `nix-build`
  * Interactive development via `nix-shell` and `cabal`
  * Easily use any version of GHC in `nixpkgs`
  * Works with [direnv][]

Geting Started
--------------

Create a `default.nix` file that looks something like this:

```nix
{ pkgs ? import <nixpkgs> {}
}:

let
  nix-hs-url = "https://github.com/pjones/nix-hs.git";
  nix-hs = import "${fetchGit nix-hs-url}/default.nix" {inherit pkgs;};

in nix-hs {
  cabal = ./mypackage.cabal;
}
```

That's it!  Now `nix-build` and `nix-shell` just work!

Configuration
-------------

In addition to the `cabal` argument to the `nix-hs` function, there
are other ways to control how your package is built.

### Enable Flags from the Cabal File ###

If you have a flag defined in your package's cabal file you can enable
it using the `flags` argument:

```nix
nix-hs {
  cabal = ./mypackage.cabal;
  flags = [ "someflagname" ];
}
```

### Using a Broken Package ###

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

Integrating Your Text Editor and Shell
--------------------------------------

The best way to let your text editor and shell use the environment
created from Nix is to use [direnv][].  Here's an example `.envrc`
file:

```sh
# -*- sh -*-

# Load an environment from Nix:
use nix
```

A Word About Automatic Shell Detection
--------------------------------------

The `nix-hs` function automatically detects if it's being run inside a
`nix-shell` and returns an appropriate environment instead of a
package derivation.  Sometimes that's not what you want.

If what you really want is to load the package binaries you can use
the `bin` attribute of the derivation.  For example:

```nix
{ pkgs ? import <nixpkgs> { }
}:

let
  zxcvbn-hs = import ../default.nix { inherit pkgs; };

in pkgs.mkShell {
  buildInputs = with pkgs; [
    zxcvbn-hs.bin
  ];
}
```

This file creates a shell environment that includes the binaries from
the `zxcvbn-hs` package, which is using the `nix-hs` function in
`../default.nix`.

[haskell]: https://www.haskell.org/
[nixpkgs]: https://nixos.org/nix/
[direnv]: https://github.com/direnv/direnv
