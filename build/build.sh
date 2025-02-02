#!/bin/bash
mkdir -p SecureBin
mkdir -p SecureVerify
# Set filenames
BINARY_FILE="./Full_bin/program.bin"
SIGNED_BINARY="./SecureBin/signed_firmware.bin"
PRIVATE_KEY="./SecureBin/private_key.pem"
PUBLIC_KEY="./SecureBin/public_key.pem"
PUBLIC_KEY_DER="./SecureBin/public_key.der"
BINARY_HASH="./SecureBin/firmware_hash.bin"
SIGNATURE="./SecureBin/signature.bin"

VERIFIED_SIGNATURE="./SecureVerify/verified_signature.bin"
VERIFIED_HASH="./SecureVerify/verified_hash.bin"
EXTRACTED_FIRMWARE="./SecureVerify/firmware_extracted.bin"

# Step 1: Generate RSA Key Pair (if not already available)
echo "Generating RSA Key Pair..."
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$PRIVATE_KEY"
openssl rsa -in "$PRIVATE_KEY" -pubout -out "$PUBLIC_KEY"

# Convert Public Key to DER format for HSE provisioning
echo "Converting public key to DER format..."
openssl rsa -in "$PRIVATE_KEY" -pubout -outform DER -out "$PUBLIC_KEY_DER"

# Step 2: Compute SHA-256 Hash of the Binary
echo "Computing SHA-256 hash of firmware..."
openssl dgst -sha256 -binary "$BINARY_FILE" > "$BINARY_HASH"

# Step 3: Sign the Hash using RSA Private Key
echo "Signing the hash with private key..."
openssl pkeyutl -sign -inkey "$PRIVATE_KEY" -in "$BINARY_HASH" -out "$SIGNATURE"

# Step 4: Append Signature to the Binary
echo "Appending signature to the binary..."
cat "$BINARY_FILE" "$SIGNATURE" > "$SIGNED_BINARY"

echo "Signed firmware created: $SIGNED_BINARY"

# Step 5: Verification on the Board Side
echo "Extracting firmware and signature..."
dd if="$SIGNED_BINARY" bs=1 count=256 skip=$(stat --format=%s "$BINARY_FILE") of="$VERIFIED_SIGNATURE"
dd if="$SIGNED_BINARY" bs=1 count=$(stat --format=%s "$BINARY_FILE") of="$EXTRACTED_FIRMWARE"

# Step 6: Compute SHA-256 Hash of Extracted Firmware
echo "Computing hash of extracted firmware..."
openssl dgst -sha256 -binary "$EXTRACTED_FIRMWARE" > firmware_hash_verify.bin

# Step 7: Verify the Signature
echo "Verifying the signature..."
openssl pkeyutl -verify -pubin -inkey "$PUBLIC_KEY" -in "$VERIFIED_SIGNATURE" -out "$VERIFIED_HASH"

diff firmware_hash_verify.bin "$VERIFIED_HASH" && echo "Signature Valid!" || echo "Signature Invalid!"

echo "***********************************************"
echo "************** Process completed..*************"
echo "***********************************************"
