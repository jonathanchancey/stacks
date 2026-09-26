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
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          git-of-theseus = pkgs.callPackage ./tools/nix/git-of-theseus.nix {
            python3Packages = pkgs.python312Packages;
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
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

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          inherit (self.packages.${system}) git-of-theseus;

          formatting =
            pkgs.runCommand "nix-formatting"
              {
                nativeBuildInputs = [ pkgs.nixfmt ];
              }
              ''
                nixfmt --check ${./flake.nix}
                find ${./tools/nix} -name '*.nix' -exec nixfmt --check {} +
                touch "$out"
              '';

          tasks =
            pkgs.runCommand "devshell-tasks"
              {
                nativeBuildInputs = [
                  pkgs.git
                  pkgs.go-task
                  pkgs.python312
                  self.packages.${system}.git-of-theseus
                ];
              }
              ''
                cp ${./taskfile.yaml} taskfile.yaml
                mkdir tools
                cp -r ${./tools/taskfiles} tools/taskfiles
                bash ${./tools/nix/check-tasks.sh}
                touch "$out"
              '';
        }
      );
    };
}
