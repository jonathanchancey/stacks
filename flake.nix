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
        rec {
          git-of-theseus = pkgs.callPackage ./tools/nix/git-of-theseus.nix {
            python3Packages = pkgs.python312Packages;
          };
          flux-local = pkgs.callPackage ./tools/nix/flux-local.nix {
            python3Packages = pkgs.python313Packages;
          };
          toolchain = pkgs.buildEnv {
            name = "stacks-toolchain";
            paths = [
              git-of-theseus
              flux-local
            ]
            ++ (with pkgs; [
              age
              cloudflared
              fluxcd
              git
              go-task
              kubeconform
              kubectl
              kubernetes-helm
              kustomize
              python313
              sops
              talosctl
              yq-go
            ]);
          };
        }
      );

      devShells = forAllSystems (
        { system, pkgs }:
        {
          default = pkgs.mkShellNoCC {
            packages = [ self.packages.${system}.toolchain ];
          };
        }
      );

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixfmt-tree);

      checks = forAllSystems (
        { system, pkgs }:
        import ./tools/nix/checks.nix {
          inherit pkgs;
          inherit (self.packages.${system}) git-of-theseus flux-local toolchain;
        }
      );
    };
}
