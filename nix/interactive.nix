# An interactive development environment.
{ # The Haskell package set with overrides:
  haskell,

  # The Haskell packages whose dependencies need to be in the package
  # set (a list of packages):
  packages,

  # Additional build inputs to put into environment:
  buildInputs ? [ ]
}:

haskell.shellFor {
  packages = _: packages;
  withHoogle = true;
  buildInputs =
    buildInputs
    ++ (with haskell;
      [ cabal-install
        ghcide
        hasktags
        hlint
        hoogle
        ormolu
      ]);
}
