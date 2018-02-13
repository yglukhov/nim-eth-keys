# Copyright (c) 2018 Status Research & Development GmbH
# Distributed under the MIT License (license terms are at http://opensource.org/licenses/MIT).

# In Nim this must be in a separate files from datatypes to avoid recursive dependencies
# between datatypes <-> ecdsa

# Note: for now only a native pure Nim backend is supported
# In the future alternative, proven crypto backend will be added like libsecpk1

import ./private/hex, ./datatypes
import keccak_tiny, ttmath

import ./backend_native/ecdsa

# ################################
# Initialization

proc initPublicKey*(hexString: string): PublicKey =
  assert hexString.len == 128
  result.raw_key[0] = hexToUInt256(hexString[0..<64])
  result.raw_key[1] = hexToUInt256(hexString[64..<128])

proc initPrivateKey*(hexString: string): PrivateKey =
  assert hexString.len == 64
  result.raw_key = hexToUInt256(hexString)
  result.public_key = private_key_to_public_key(result)

# ################################
# Hex
proc toHex*(key: PrivateKey): string =
  result = key.raw_key.toHex

proc toHex*(key: PublicKey): string =
  result = key.raw_key[0].toHex
  result.add key.raw_key[1].toHex

# ################################
# Public key interface
proc recover_pubkey_from_msg_hash*(message_hash: Hash[256], sig: Signature): PublicKey {.inline.}=
  ecdsa_raw_recover(message_hash, sig)

proc recover_pubkey_from_msg*(message: string, sig: Signature): PublicKey {.inline.}=
  let message_hash = keccak_256(message)
  result = recover_pubkey_from_msg_hash(message_hash, sig)

proc verify_msg_hash*(key: PublicKey, message_hash: Hash[256], sig: Signature): bool {.inline.}=
  key == ecdsa_raw_recover(message_hash, sig)

proc verify_msg*(key: PublicKey, message: string, sig: Signature): bool {.inline.} =
  let message_hash = keccak_256(message)
  key == ecdsa_raw_recover(message_hash, sig)

# ################################
# Private key interface
proc sign_msg_hash*(key: PrivateKey, message_hash: Hash[256]): Signature {.inline.}=
  ecdsa_raw_sign(message_hash, key)

proc sign_msg*(key: PrivateKey, message: string): Signature {.inline.} =
  let message_hash = keccak_256(message)
  ecdsa_raw_sign(message_hash, key)

# ################################
# Signature interface is a duplicate of the public key interface