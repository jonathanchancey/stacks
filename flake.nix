{
  description = "Stacks development tools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          }
        );
    in
    {
      packages = forAllSystems (
        { pkgs, ... }:
        {
          git-of-theseus = pkgs.callPackage ./tools/nix/git-of-theseus.nix {
            python3Packages = pkgs.python312Packages;
          };
        }
      );

      devShells = forAllSystems (
        { system, pkgs }:
        {
          default = pkgs.mkShellNoCC {
            packages = [
              pkgs.git
              pkgs.go-task
              self.packages.${system}.git-of-theseus
            ];
          };
        }
      );

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixfmt-tree);

      checks = forAllSystems (
        { system, pkgs }:
        import ./tools/nix/checks.nix {
          inherit pkgs;
          inherit (self.packages.${system}) git-of-theseus;
        }
      );
    };
}
