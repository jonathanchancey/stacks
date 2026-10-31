import os
from pathlib import Path
import ssl
import subprocess
import sys


bundle, directory, chains_directory = sys.argv[1:]
defaults = ssl.get_default_verify_paths()
assert defaults.cafile == bundle, defaults
assert defaults.capath == directory, defaults
assert os.environ["NIX_SSL_CERT_FILE"] == bundle
assert os.environ["REQUESTS_CA_BUNDLE"] == bundle

chains = sorted(Path(chains_directory).glob("*.pem"))
assert len(chains) == 12, chains
stores = {
    "default bundle": ["-CAfile", defaults.cafile, "-no-CApath"],
    "default directory": ["-CApath", defaults.capath, "-no-CAfile"],
}
for name, arguments in stores.items():
    for chain in chains:
        result = subprocess.run(
            [
                "openssl", "verify", "-no-CAstore", *arguments,
                # freeze verification at disclosure so expiry cannot hide a regression.
                "-attime", "1792497600", "-purpose", "sslserver",
                "-verify_hostname", chain.stem,
                "-untrusted", str(chain), str(chain),
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode != 0, f"{name} accepted {chain.name}"
        assert any(message in result.stderr for message in (
            "certificate rejected", "unable to get local issuer certificate",
        )), result.stderr
    print(f"{name}: rejected all 12 compromised chains")
