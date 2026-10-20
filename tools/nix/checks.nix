{
  pkgs,
  cacert,
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

  trust =
    pkgs.runCommand "toolchain-trust"
      {
        nativeBuildInputs = [ pkgs.openssl ];
        chains = pkgs.fetchzip {
          url = "https://emudhra.we-have-a-problem.com/chains.zip";
          hash = "sha256-zvAue50iyz1c/AVIeBrL9C5+MXQH02LsBzN5x3SHKhU=";
        };
        PYTHONPATH = pkgs.python313Packages.makePythonPath flux-local.propagatedBuildInputs;
      }
      ''
        # simulate the host trust paths inherited by an absolute profile invocation.
        export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
        export SSL_CERT_FILE="$NIX_SSL_CERT_FILE" SSL_CERT_DIR=/etc/ssl/certs
        ${toolchain}/bin/python3 ${./check-trust.py} \
          ${cacert}/etc/ssl/certs/ca-bundle.crt ${cacert.hashed}/etc/ssl/certs "$chains"
        touch "$out"
      '';

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
