# An interactive development environment.
{

# The Haskell package set with overrides:
haskell,

# The version of GHC we are using:
compilerName,

# The Haskell packages whose dependencies need to be in the package
# set (a list of packages):
packages,

# nixpkgs:
pkgs,

# Additional build inputs to put into environment:
buildInputs ? [ ] }:

let tools = import ../shell/shell.nix { ghc = compilerName; };
in haskell.shellFor {
  packages = _: packages;
  withHoogle = true;
  buildInputs = buildInputs ++ tools.buildInputs;
}
