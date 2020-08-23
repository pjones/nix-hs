{ compilerName
}:
let
  helpers = pkgs: import ./lib.nix { inherit pkgs; };

  # Modified version of the nixpkgs Haskell lib:
  hlib = pkgs:
    pkgs.haskell.lib // {
      inherit pkgs compilerName;
      inherit (helpers pkgs) unBreak addPostPatch;
    };

  overlayForHaskell = overrides: self: super: {
    haskell = super.haskell // {
      packages = super.haskell.packages // {
        ${compilerName} =
          super.haskell.packages.${compilerName}.override (orig: {
            overrides =
              super.lib.composeExtensions (orig.overrides or (_: _: { }))
                (overrides (hlib self));
          });
      };
    };

    haskellPackages = self.haskell.packages.${compilerName};
  };
in
overlayForHaskell
