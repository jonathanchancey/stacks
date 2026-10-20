#!/usr/bin/env python3
"""reject public bundles containing the emudhra compromise's trust anchors."""

import hashlib
from pathlib import Path
import ssl
import sys


bundle = Path(sys.argv[1])
# sha256 fingerprints from https://emudhra.we-have-a-problem.com/roots.json
blocked = {
    "7dd78d5f4f13459a83dff9abbba62edbaf6f2d102bf257fd712f4d9f2746ed8d",
    "f2edaaff3d9b701fb4d14c9f285f8c0bad90fc3bcc1fa07d47f4718edaba34a5",
    "d7a7a0fb5d7e2731d771e9484ebcdef71d5f0c3e0a2948782bc83ee0ea699ef4",
    "86a1ecba089c4a8d3bbe2734c612ba341d813e043cf9e8a862cd5c57a36bbe6b",
}
context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
context.load_verify_locations(cafile=str(bundle))
roots = {
    hashlib.sha256(certificate).hexdigest()
    for certificate in context.get_ca_certs(binary_form=True)
}
if not roots:
    sys.exit("public ca bundle has no trust anchors")
if roots & blocked:
    sys.exit("public ca bundle contains an affected emudhra trust anchor")
print(f"public ca bundle: {len(roots)} roots, no affected emudhra trust anchors")
