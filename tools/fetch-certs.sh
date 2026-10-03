#!/bin/bash
# Refreshes layout/usr/share/gcpassesfix/certs from the sources the bag.xml
# Game Center guide points to: the tlsroot.litten.ca bundle (Hanabi) and the
# Apple certificates listed on developer.bag-xml.com. Everything is stored as
# DER; expired certificates are skipped.
set -euo pipefail

cd "$(dirname "$0")/.."
out=layout/usr/share/gcpassesfix/certs
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

T=https://tlsroot.litten.ca
A=https://www.apple.com/certificateauthority
certs=(
	"AmazonRootCA1           $T/AmazonRootCA1.cer"
	"AmazonRootCA2           $T/AmazonRootCA2.cer"
	"AmazonRootCA3           $T/AmazonRootCA3.cer"
	"AmazonRootCA4           $T/AmazonRootCA4.cer"
	"AppleRootCA             https://www.apple.com/appleca/AppleIncRootCertificate.cer"
	"AppleRootCA-G2          $A/AppleRootCA-G2.cer"
	"AppleRootCA-G3          $A/AppleRootCA-G3.cer"
	"AppleISTCA8-G1          $A/AppleISTCA8G1.cer"
	"AppleWWDRCA-G2          $T/intermediate/AppleWWDRCAG2.cer"
	"AppleWWDRCA-G3          $T/intermediate/AppleWWDRCAG3.cer"
	"AppleWWDRCA-G4          $T/intermediate/AppleWWDRCAG4.cer"
	"AppleWWDRCA-G5          $T/intermediate/AppleWWDRCAG5.cer"
	"AppleWWDRCA-G6          $T/intermediate/AppleWWDRCAG6.cer"
	"AppleWWDRMPCA1-G1       $T/intermediate/AppleWWDRMPCA1G1.cer"
	"COMODO-ECC              $T/comodoECC.cer"
	"COMODO-RSA              $T/comodoRSA.cer"
	"DigiCertGlobalRootG2    $T/DigiCertGlobalRootG2.crt"
	"DigiCertGlobalRootG3    $T/DigiCertGlobalRootG3.crt"
	"DigiCertHighAssuranceEV $T/DigiCertHighAssuranceEVRootCA.crt"
	"Entrust-EC1             $T/entrust_ec1_ca.cer"
	"Entrust-G2              $T/entrust_g2_ca.cer"
	"GeoTrustPCA             $T/GeoTrustPCA.crt"
	"GeoTrustPCA-G2          $T/GeoTrustPCA-G2.crt"
	"GeoTrustPCA-G3          $T/GeoTrustPCA-G3.crt"
	"GlobalSign-E46          $T/globalsign/roote46.crt"
	"GlobalSign-R3           $T/globalsign/Root-R3.crt"
	"GlobalSign-R4           $T/globalsign/gsr4.crt"
	"GlobalSign-R46          $T/globalsign/rootr46.crt"
	"GlobalSign-R5           $T/globalsign/Root-R5.crt"
	"GlobalSign-R6           $T/globalsign/root-r6.crt"
	"GTS-R1                  $T/gts/r1.crt"
	"GTS-R2                  $T/gts/r2.crt"
	"GTS-R3                  $T/gts/r3.crt"
	"GTS-R4                  $T/gts/r4.crt"
	"ISRG-X1                 $T/isrgrootx1.der"
	"ISRG-X2                 $T/isrg-root-x2.der"
	"Starfield-G2            $T/SFSRootCAG2.cer"
	"USERTrust-ECC           $T/USERTrustECCCertificationAuthority.crt"
	"USERTrust-RSA           $T/USERTrustRSACertificationAuthority.crt"
)

for line in "${certs[@]}"; do
	read -r name url <<<"$line"
	curl -sfL --retry 2 -m 30 "$url" -o "$tmp/raw"
	if ! openssl x509 -inform DER -in "$tmp/raw" -noout 2>/dev/null; then
		openssl x509 -in "$tmp/raw" -outform DER -out "$tmp/raw.der"
		mv "$tmp/raw.der" "$tmp/raw"
	fi
	if ! openssl x509 -inform DER -in "$tmp/raw" -noout -checkend 0 >/dev/null; then
		echo "skip $name: expired"
		continue
	fi
	mv "$tmp/raw" "$tmp/$name.cer"
	echo "ok   $name"
done

rm -f "$out"/*.cer
mkdir -p "$out"
mv "$tmp"/*.cer "$out"/
echo "$(ls "$out" | wc -l) certificates in $out"
