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
      hash = "sha256-didL5e+LAW6A6gq/e29hKtx2qJ92E9Ln9+NVCvW54YY=";
    };
    aarch64-linux = {
      archive = "linux_arm64";
      hash = "sha256-f1FIFIkN9KCViHlDrmBr4aivh4YGt70Fde/nVALNONw=";
    };
    x86_64-linux = {
      archive = "linux_amd64";
      hash = "sha256-N+sM2RpnUjQHVDdXQ6phbCY82DZ85ZSr1C7pVeHsAJk=";
    };
  };
  platform = platforms.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation rec {
  pname = "flate";
  version = "0.6.5";

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
