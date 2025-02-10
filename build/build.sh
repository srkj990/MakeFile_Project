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
#CMAC 
CMAC_KEY="./SecureBin/cmac_key.bin"
CMAC_SIGNATURE="./SecureBin/firmware_cmac.bin"
ENCRYPTED_FIRMWARE="./SecureBin/encrypted_firmware.bin"

VERIFIED_SIGNATURE="./SecureVerify/verified_signature.bin"
VERIFIED_HASH="./SecureVerify/verified_hash.bin"
EXTRACTED_FIRMWARE="./SecureVerify/firmware_extracted.bin"
#CMAC 
RECEIVED_CMAC="./SecureVerify/received_cmac.bin"
COMPUTED_CMAC="./SecureVerify/computer_cmac.bin"

# Step 1: Generate RSA Key Pair (if not already available)
echo "Generating RSA Key Pair..."
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$PRIVATE_KEY"
openssl rsa -in "$PRIVATE_KEY" -pubout -out "$PUBLIC_KEY"

# Convert Public Key to DER format for HSE provisioning
echo "Converting public key to DER format..."
openssl rsa -in "$PRIVATE_KEY" -pubout -outform DER -out "$PUBLIC_KEY_DER"

# Generate AES-256 CMAC Key
echo "Generating AES-256 CMAC Key..."
openssl rand -hex 32 | tr -d '\r\n' > "$CMAC_KEY"

# Step 2: Compute SHA-256 Hash of the Binary
echo "Computing SHA-256 hash of firmware..."
openssl dgst -sha256 -binary "$BINARY_FILE" > "$BINARY_HASH"

# Compute CMAC Over the Firmware
echo "Computing CMAC over firmware..."
CMAC_KEY_HEX=$(cat "$CMAC_KEY" | tr -d '\r\n')
openssl dgst -mac cmac -macopt cipher:aes-256-cbc -macopt hexkey:"$CMAC_KEY_HEX" -binary "$BINARY_FILE" > "$CMAC_SIGNATURE"
echo "CMAC Signature: $(xxd -p "$CMAC_SIGNATURE")"

# Step 3: Sign the Hash using RSA Private Key
echo "Signing the hash with private key..."
openssl rsautl -sign -inkey "$PRIVATE_KEY" -in "$BINARY_HASH" -out "$SIGNATURE"

# Step 4: Append Signature to the Binary
echo "Appending signature to the binary..."
cat "$BINARY_FILE" "$SIGNATURE" "$CMAC_SIGNATURE" > "$SIGNED_BINARY"

echo "Signed firmware created: $SIGNED_BINARY"

# Step 5: Verification on the Board Side
echo "Extracting firmware and signature and cmac signature..."
dd if="$SIGNED_BINARY" bs=1 count=256 skip=$(stat --format=%s "$BINARY_FILE") of="$VERIFIED_SIGNATURE"
dd if="$SIGNED_BINARY" bs=1 count=32 skip=$(($(stat --format=%s "$BINARY_FILE") + 256)) of="$RECEIVED_CMAC"
dd if="$SIGNED_BINARY" bs=1 count=$(stat --format=%s "$BINARY_FILE") of="$EXTRACTED_FIRMWARE"

# Step 6a: Compute SHA-256 Hash of Extracted Firmware
echo "Computing hash of extracted firmware..."
openssl dgst -sha256 -binary "$EXTRACTED_FIRMWARE" > firmware_hash_verify.bin

# Step 6b: Compute CMAC over the firmware using AES-256
echo "Computing CMAC over extracted firmware..."
openssl dgst -mac cmac -macopt cipher:aes-256-cbc -macopt hexkey:"$CMAC_KEY_HEX" -binary "$EXTRACTED_FIRMWARE" > "$COMPUTED_CMAC"
echo "Computed CMAC: $(xxd -p "$COMPUTED_CMAC")"
echo "Received CMAC: $(xxd -p "$RECEIVED_CMAC")"

# Step 7: Verify the Signature
echo "Verifying the signature..."
openssl rsautl -verify -pubin -inkey "$PUBLIC_KEY" -in "$VERIFIED_SIGNATURE" -out "$VERIFIED_HASH"
diff firmware_hash_verify.bin "$VERIFIED_HASH" && echo "Signature Valid!" || echo "Signature Invalid!"

# Step 7b: Verify the CMAC Signature
echo "Verifying the CMAC signature..."
cmp -l "$RECEIVED_CMAC" "$COMPUTED_CMAC" && echo "CMAC Valid!" || echo "CMAC Invalid!"

echo "***********************************************"
echo "************** Process completed..*************"
echo "***********************************************"