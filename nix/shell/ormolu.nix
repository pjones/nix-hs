{ sources
, pkgs
, compilerName
, justStaticExecutables
}:
let
  package = import sources.ormolu {
    inherit pkgs;
    ormoluCompiler = compilerName;
  };
in
justStaticExecutables package.ormolu
