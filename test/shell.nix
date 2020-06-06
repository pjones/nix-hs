{ sources ? import ../nix/sources.nix, pkgs ? import sources.nixpkgs { } }:

pkgs.mkShell {
  name = "nix-hs-test-shell";
  buildInputs = with pkgs; [ bash jq ];
}
