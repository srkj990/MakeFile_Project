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
CMAC_KEY="./SecureBin/cmac_key.bin"
CMAC_SIGNATURE="./SecureBin/firmware_cmac.bin"
ENCRYPTED_FIRMWARE="./SecureBin/encrypted_firmware.bin"
AES_KEY="./SecureBin/aes_key.bin"
AES_IV="./SecureBin/aes_iv.bin"

VERIFIED_SIGNATURE="./SecureVerify/verified_signature.bin"
VERIFIED_HASH="./SecureVerify/verified_hash.bin"
EXTRACTED_FIRMWARE="./SecureVerify/firmware_extracted.bin"
FIRMWARE_HASH_VERIFY="./SecureVerify/firmware_hash_verify.bin"
VERIFIED_CMAC="./SecureVerify/verified_cmac.bin"
DECRYPTED_FIRMWARE="./SecureVerify/decrypted_firmware.bin"

# Generate RSA Key Pair if not already present
echo "Generating RSA Key Pair..."
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$PRIVATE_KEY"
openssl rsa -in "$PRIVATE_KEY" -pubout -out "$PUBLIC_KEY"
openssl rsa -in "$PRIVATE_KEY" -pubout -outform DER -out "$PUBLIC_KEY_DER"

# Generate AES-256 CMAC Key and AES Encryption Key
echo "Generating AES-256 CMAC Key and Encryption Key..."
openssl rand -hex 32 | tr -d '\r\n' > "$CMAC_KEY"
openssl rand -hex 32 | tr -d '\r\n' > "$AES_KEY"
openssl rand -hex 16 | tr -d '\r\n' > "$AES_IV"

# Compute SHA-256 Hash of the Binary
echo "Computing SHA-256 hash of firmware..."
openssl dgst -sha256 -binary "$BINARY_FILE" > "$BINARY_HASH"

# Sign the Hash using RSA Private Key
echo "Signing the hash with private key..."
openssl rsautl -sign -inkey "$PRIVATE_KEY" -in "$BINARY_HASH" -out "$SIGNATURE"

# Compute CMAC Over the Firmware
echo "Computing CMAC over firmware..."
CMAC_KEY_HEX=$(cat "$CMAC_KEY" | tr -d '\r\n')
openssl dgst -mac cmac -macopt cipher:aes-256-cbc -macopt hexkey:"$CMAC_KEY_HEX" -binary "$BINARY_FILE" > "$CMAC_SIGNATURE"

# Encrypt the firmware using AES-256 CBC
echo "Encrypting firmware..."
AES_KEY_HEX=$(cat "$AES_KEY" | tr -d '\r\n')
AES_IV_HEX=$(cat "$AES_IV" | tr -d '\r\n')
openssl enc -aes-256-cbc -K "$AES_KEY_HEX" -iv "$AES_IV_HEX" -in "$BINARY_FILE" -out "$ENCRYPTED_FIRMWARE"

# Append Signature, CMAC, and IV to the Binary
echo "Appending signature, CMAC, and IV to the encrypted binary..."
cat "$ENCRYPTED_FIRMWARE" "$SIGNATURE" "$CMAC_SIGNATURE" "$AES_IV" > "$SIGNED_BINARY"

# Extraction for verification
file_size=$(wc -c < "$ENCRYPTED_FIRMWARE")
dd if="$SIGNED_BINARY" bs=1 count=256 skip="$file_size" of="$VERIFIED_SIGNATURE"
dd if="$SIGNED_BINARY" bs=1 count=32 skip=$(($file_size + 256)) of="$VERIFIED_CMAC"
dd if="$SIGNED_BINARY" bs=1 count=16 skip=$(($file_size + 256 + 32)) of="$AES_IV"
dd if="$SIGNED_BINARY" bs=1 count="$file_size" of="$EXTRACTED_FIRMWARE"

# Decrypt the firmware
echo "Decrypting firmware..."
IV=$(xxd -p "$AES_IV" | tr -d '\r\n')
openssl enc -aes-256-cbc -d -K "$AES_KEY_HEX" -iv "$IV" -in "$EXTRACTED_FIRMWARE" -out "$DECRYPTED_FIRMWARE"

# Verify Signature
echo "Verifying the signature..."
openssl dgst -sha256 -binary "$DECRYPTED_FIRMWARE" > "$VERIFIED_HASH"
openssl rsautl -verify -pubin -inkey "$PUBLIC_KEY" -in "$VERIFIED_HASH" -out "$VERIFIED_SIGNATURE" || echo "Signature Invalid!"

# Verify CMAC
echo "Verifying CMAC..."
openssl dgst -mac cmac -macopt cipher:aes-256-cbc -macopt hexkey:"$CMAC_KEY_HEX" -binary "$DECRYPTED_FIRMWARE" > "$FIRMWARE_HASH_VERIFY"
echo "CMAC Key: $CMAC_KEY_HEX"
echo "Verified CMAC: $(xxd -p "$VERIFIED_CMAC")"
echo "Computed CMAC: $(xxd -p "$FIRMWARE_HASH_VERIFY")"
cmp -l "$VERIFIED_CMAC" "$FIRMWARE_HASH_VERIFY" && echo "CMAC Valid!" || echo "CMAC Invalid!"

echo "Process completed."