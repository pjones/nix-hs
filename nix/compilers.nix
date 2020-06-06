{ pkgs }: {
  # List of supported compilers and their attributes:
  attrs = builtins.fromJSON (builtins.readFile ../compilers.json);

  # Calculate the name of the compiler we're going to use.
  name = compiler:
    if compiler == "default" then
      builtins.replaceStrings [ "." "-" ] [ "" "" ]
      pkgs.haskellPackages.ghc.name
    else
      let
        clean = pkgs.lib.removePrefix "ghc"
          (builtins.replaceStrings [ "." "-" ] [ "" "" ] compiler);
      in "ghc${clean}";

}
