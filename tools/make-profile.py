#!/usr/bin/env python3
# Builds GCPassesFix-Roots.mobileconfig from the DER certificates in
# layout/usr/share/gcpassesfix/certs. Installing the profile (tap it on the
# device) adds the certificates to the system trust store the supported way,
# with no entitlements and nothing written to TrustStore.sqlite3 by hand.
#
# This mirrors the certificate bundle the bag.xml Game Center guide points to
# (tlsroot.litten.ca); the profile is unsigned, so iOS shows it as "Not
# Verified" on install, like every community legacy-iOS certificate bundle.

import base64
import hashlib
import plistlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CERTS = ROOT / "layout/usr/share/gcpassesfix/certs"
OUT = ROOT / "layout/usr/share/gcpassesfix/GCPassesFix-Roots.mobileconfig"
BASE_ID = "cfd.legacyreborn.gcpassesfix"


def uuid_from(data: bytes) -> str:
    h = hashlib.sha1(data).hexdigest()
    return f"{h[0:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:32]}".upper()


def main() -> int:
    files = sorted(CERTS.glob("*.cer"))
    if not files:
        print("no certificates found", file=sys.stderr)
        return 1

    payloads = []
    for f in files:
        der = f.read_bytes()
        payloads.append({
            "PayloadType": "com.apple.security.root",
            "PayloadVersion": 1,
            "PayloadIdentifier": f"{BASE_ID}.cert.{f.stem}",
            "PayloadUUID": uuid_from(der),
            "PayloadDisplayName": f.stem,
            "PayloadCertificateFileName": f.name,
            "PayloadContent": der,
        })

    profile = {
        "PayloadType": "Configuration",
        "PayloadVersion": 1,
        "PayloadIdentifier": BASE_ID + ".roots",
        "PayloadUUID": uuid_from(b"".join(sorted(p["PayloadUUID"].encode() for p in payloads))),
        "PayloadDisplayName": "LegacyReborn root certificates",
        "PayloadOrganization": "LegacyReborn",
        "PayloadDescription": (
            "Up-to-date root and Apple WWDR certificates for legacy iOS. "
            "Needed so Game Center, the iTunes Store and iCloud can reach "
            "Apple's current servers over TLS."
        ),
        "PayloadRemovalDisallowed": False,
        "PayloadContent": payloads,
    }

    OUT.write_bytes(plistlib.dumps(profile))
    print(f"{len(payloads)} certificates -> {OUT.relative_to(ROOT)} ({OUT.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
