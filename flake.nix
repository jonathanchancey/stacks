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
      trustEnvironment = cacert: {
        NIX_SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
        SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
        SSL_CERT_DIR = "${cacert.hashed}/etc/ssl/certs";
        REQUESTS_CA_BUNDLE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
      };
      trustWrapperArgs =
        pkgs: cacert:
        pkgs.lib.mapAttrsToList (name: value: "--set ${name} ${pkgs.lib.escapeShellArg value}") (
          trustEnvironment cacert
        );
    in
    {
      packages = forAllSystems (
        { pkgs, ... }:
        let
          python = pkgs.python313.override {
            packageOverrides = final: prev: {
              certifi = prev.certifi.override { inherit cacert; };
            };
          };
          # https://emudhra.we-have-a-problem.com/ (2026-10-20)
          cacert = pkgs.cacert.overrideAttrs (old: rec {
            version = "3.131.1";
            src = pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/nss-dev/nss/refs/tags/NSS_${
                pkgs.lib.replaceStrings [ "." ] [ "_" ] version
              }_RTM/lib/ckfw/builtins/certdata.txt";
              hash = "sha256-PsK00kDcEsdH6vRQBh24SvdXxIO72jAvninOtdcL5RA=";
            };
            meta = old.meta // {
              identifiers.cpeParts = old.meta.identifiers.cpeParts // {
                inherit version;
              };
            };
          });
        in
        rec {
          inherit cacert;
          git-of-theseus = pkgs.callPackage ./tools/nix/git-of-theseus.nix {
            python3Packages = pkgs.python312Packages;
            trustWrapperArgs = trustWrapperArgs pkgs cacert;
          };
          flux-local = pkgs.callPackage ./tools/nix/flux-local.nix {
            python3Packages = python.pkgs;
            trustWrapperArgs = trustWrapperArgs pkgs cacert;
          };
          toolchain = pkgs.buildEnv {
            name = "stacks-toolchain";
            nativeBuildInputs = [ pkgs.makeWrapper ];
            # absolute profile paths (including orb resume) need the same defaults.
            postBuild = ''
              for program in "$out"/bin/*; do
                wrapProgram "$program" ${pkgs.lib.concatStringsSep " " (trustWrapperArgs pkgs cacert)}
              done
            '';
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
            env = trustEnvironment self.packages.${system}.cacert;
            packages = [ self.packages.${system}.toolchain ];
          };
        }
      );

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixfmt-tree);

      checks = forAllSystems (
        { system, pkgs }:
        import ./tools/nix/checks.nix {
          inherit pkgs;
          inherit (self.packages.${system})
            cacert
            git-of-theseus
            flux-local
            toolchain
            ;
        }
      );
    };
}
