{
  pkgs,
  git-of-theseus,
  flux-local,
  toolchain,
}:
let
  inherit (pkgs) lib;
  nixSource = lib.fileset.toSource {
    root = ../..;
    fileset = lib.fileset.unions [
      ../../flake.nix
      (lib.fileset.fileFilter (file: file.hasExt "nix") ./.)
    ];
  };
in
{
  inherit git-of-theseus flux-local toolchain;

  flux-local-ci-version = pkgs.runCommand "flux-local-ci-version" { } ''
    versions=$(sed -n 's|.*ghcr.io/allenporter/flux-local:v\([0-9.]*\).*|\1|p' ${../../.github/workflows/flux-diff.yaml} | sort -u)
    test "$versions" = "${flux-local.version}"
    touch "$out"
  '';

  orb-scripts = pkgs.runCommand "orb-script-syntax" { } ''
    bash -n ${../../.agents/setup}
    bash -n ${../../.agents/resume}
    touch "$out"
  '';

  formatting = pkgs.runCommand "nix-formatting" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
    find ${nixSource} -name '*.nix' -exec nixfmt --check {} +
    touch "$out"
  '';

  tasks = pkgs.stdenvNoCC.mkDerivation {
    name = "theseus-tasks";
    src = lib.fileset.toSource {
      root = ../..;
      fileset = lib.fileset.unions [
        ../../taskfile.yaml
        ../taskfiles
      ];
    };

    nativeBuildInputs = [
      pkgs.git
      pkgs.go-task
      pkgs.python312
      git-of-theseus
    ];
    dontConfigure = true;
    dontBuild = true;
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      bash ${./check-tasks.sh}
      runHook postCheck
    '';
    installPhase = ''
      runHook preInstall
      touch "$out"
      runHook postInstall
    '';
  };
}
