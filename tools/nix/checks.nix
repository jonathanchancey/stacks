{
  pkgs,
  cacert,
  git-of-theseus,
  flate,
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
  inherit git-of-theseus toolchain;

  flate = pkgs.runCommand "flate-runtime" { } ''
    bash ${./check-flate.sh} ${flate} ${lib.getExe pkgs.gitMinimal}
    touch "$out"
  '';

  trust =
    pkgs.runCommand "toolchain-trust"
      {
        nativeBuildInputs = [ pkgs.openssl ];
        chains = pkgs.fetchzip {
          # keep the original twelve-chain fixture independent of advisory updates.
          url = "https://raw.githubusercontent.com/galadran/we-have-a-problem.com/87b66fe4d2378a4a6504a5d4d434b7aa49a8285e/chains.zip";
          hash = "sha256-zvAue50iyz1c/AVIeBrL9C5+MXQH02LsBzN5x3SHKhU=";
        };
      }
      ''
        # simulate the host trust paths inherited by an absolute profile invocation.
        export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
        export SSL_CERT_FILE="$NIX_SSL_CERT_FILE" SSL_CERT_DIR=/etc/ssl/certs
        ${toolchain}/bin/python3 ${./check-trust.py} \
          ${cacert}/etc/ssl/certs/ca-bundle.crt ${cacert.hashed}/etc/ssl/certs "$chains"
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
