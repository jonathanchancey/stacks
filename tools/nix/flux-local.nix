{
  lib,
  fetchPypi,
  fluxcd,
  gitMinimal,
  kubernetes-helm,
  kustomize,
  python3Packages,
}:

python3Packages.buildPythonApplication rec {
  pname = "flux-local";
  version = "8.4.0";
  pyproject = true;

  src = fetchPypi {
    pname = "flux_local";
    inherit version;
    hash = "sha256-aOSoVF4Gaib/oLbv+boGNuGdANc4+b/GVgaimjpviAs=";
  };

  build-system = [ python3Packages.setuptools ];

  dependencies = with python3Packages; [
    aiofiles
    gitpython
    mashumaro
    nest-asyncio
    oras
    pytest
    pytest-asyncio
    python-slugify
    pyyaml
  ];

  makeWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        fluxcd
        gitMinimal
        kubernetes-helm
        kustomize
      ]
    }"
  ];
  pythonImportsCheck = [ "flux_local" ];

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    bash ${./check-flux-local.sh} "$out" "${lib.getExe gitMinimal}"
    runHook postInstallCheck
  '';

  meta = {
    description = "build and validate flux resources locally";
    homepage = "https://github.com/allenporter/flux-local";
    license = lib.licenses.asl20;
    mainProgram = "flux-local";
  };
}
