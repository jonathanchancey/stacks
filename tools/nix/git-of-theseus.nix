{
  lib,
  fetchPypi,
  gitMinimal,
  python3Packages,
}:

python3Packages.buildPythonApplication rec {
  pname = "git-of-theseus";
  version = "0.3.4";
  format = "wheel";

  src = fetchPypi {
    pname = "git_of_theseus";
    inherit version format;
    dist = "py3";
    python = "py3";
    hash = "sha256-ZuxG6o+mE/CpY7x1ONv8ek7Luj+bKT2Y8aHwz87Xay0=";
  };

  dependencies = with python3Packages; [
    gitpython
    matplotlib
    numpy
    pygments
    python-dateutil
    tqdm
    wcmatch
  ];

  makeWrapperArgs = [ "--prefix PATH : ${lib.makeBinPath [ gitMinimal ]}" ];
  pythonImportsCheck = [ "git_of_theseus" ];

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    bash ${./check-theseus.sh} "$out" "${lib.getExe gitMinimal}" "${python3Packages.python.interpreter}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Analyze how code in a Git repository changes over time";
    homepage = "https://github.com/erikbern/git-of-theseus";
    license = lib.licenses.asl20;
    mainProgram = "git-of-theseus-analyze";
  };
}
