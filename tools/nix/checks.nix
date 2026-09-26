{ pkgs, git-of-theseus }:
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
  inherit git-of-theseus;

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
