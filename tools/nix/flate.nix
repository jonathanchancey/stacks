{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  gitMinimal,
  trustWrapperArgs,
}:

let
  platforms = {
    aarch64-darwin = {
      archive = "darwin_arm64";
      hash = "sha256-uIHPvvZRCE0Mm5fGwtYBAwIrQ6LK7dwdBv6/k8Bl3X0=";
    };
    aarch64-linux = {
      archive = "linux_arm64";
      hash = "sha256-SuUC5WBU7pxQGZlVVIVsH2+PRLP2/vCHcEstMcJ6ucY=";
    };
    x86_64-linux = {
      archive = "linux_amd64";
      hash = "sha256-dpQPtv8GDgmkDhqDX8nFzSThj90p5OeTgoUoIeCsAcI=";
    };
  };
  platform = platforms.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation rec {
  pname = "flate";
  version = "0.8.0";

  src = fetchurl {
    url = "https://github.com/home-operations/flate/releases/download/v${version}/flate_${version}_${platform.archive}.tar.gz";
    inherit (platform) hash;
  };
  sourceRoot = ".";

  nativeBuildInputs = [ makeWrapper ];
  nativeInstallCheckInputs = [ gitMinimal ];
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 flate "$out/bin/flate"
    wrapProgram "$out/bin/flate" ${lib.concatStringsSep " " trustWrapperArgs}
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    bash ${./check-flate.sh} "$out" "${lib.getExe gitMinimal}"
    runHook postInstallCheck
  '';

  meta = {
    description = "render, test, and diff flux resources offline";
    homepage = "https://github.com/home-operations/flate";
    license = lib.licenses.agpl3Only;
    mainProgram = "flate";
    platforms = builtins.attrNames platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
