# An interactive development environment.
{
  # nixpkgs:
  pkgs
, # The version of GHC we are using.
  compilerName
, # The derivation to add an interactive environment to.  If instead of
  # a derivation an attribute set is given, create an interactive
  # environment for all packages in the set.
  drv
, # Additional build inputs to put into environment.
  buildInputs ? [ ]
}:
let
  tools = import ./shell {
    compiler = compilerName;
  };

  shellFor = packages:
    pkgs.haskell.packages.${compilerName}.shellFor {
      packages = _: packages;
      withHoogle = true;
      buildInputs = buildInputs ++ tools.buildInputs;
    };

in
if pkgs.lib.isDerivation drv
then
  drv.overrideAttrs
    (orig: {
      passthru = orig.passthru or { } // {
        interactive = shellFor [ drv ];
      };
    })
else
  drv // {
    interactive = shellFor (builtins.attrValues drv);
  }
