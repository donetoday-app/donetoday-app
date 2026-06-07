import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class EncryptionHelper {
  /// Generate a 32-byte key from a secret using SHA-256
  static encrypt.Key _deriveKey(String secret) {
    final bytes = utf8.encode(secret.trim().toUpperCase());
    final digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypt Data with dual-key protection (Password & Recovery Phrase)
  static Map<String, dynamic> encryptData(
    String jsonData,
    String password,
    String recoveryPhrase,
  ) {
    // 1. Generate a random Master Key
    final masterKeyBytes = encrypt.IV.fromSecureRandom(32).bytes;
    final masterKey = encrypt.Key(masterKeyBytes);

    // 2. Encrypt the data with the Master Key
    final iv = encrypt.IV.fromSecureRandom(16);
    final dataEncrypter = encrypt.Encrypter(encrypt.AES(masterKey));
    final encryptedData = dataEncrypter.encrypt(jsonData, iv: iv);

    // 3. Protect Master Key with Password
    final derivedKeyA = _deriveKey(password);
    final encryptedMasterKeyA = _wrapKey(masterKeyBytes, derivedKeyA);

    // 4. Protect Master Key with Recovery Phrase
    final derivedKeyB = _deriveKey(recoveryPhrase);
    final encryptedMasterKeyB = _wrapKey(masterKeyBytes, derivedKeyB);

    return {
      'payload': encryptedData.base64,
      'iv': iv.base64,
      'keyA': encryptedMasterKeyA,
      'keyB': encryptedMasterKeyB,
      'v': 5, // New version for simplified dual-key
    };
  }

  /// Decrypt data using either Password or Recovery Phrase
  static String? decryptData(
    Map<String, dynamic> encryptedData,
    String secret,
  ) {
    try {
      final v = encryptedData['v'];
      if (v != 5) {
        debugPrint("Unsupported encryption version: $v.");
        return null;
      }

      final iv = encrypt.IV.fromBase64(encryptedData['iv']);
      final payload = encrypt.Encrypted.fromBase64(encryptedData['payload']);

      // Try the secret as KeyA and then KeyB
      final derivedKey = _deriveKey(secret);

      for (var keyField in ['keyA', 'keyB']) {
        final wrappedKey = encryptedData[keyField];
        if (wrappedKey == null) continue;

        final masterKeyBytes = _unwrapKey(wrappedKey, derivedKey);
        if (masterKeyBytes != null) {
          final masterKey = encrypt.Key(masterKeyBytes);
          final dataEncrypter = encrypt.Encrypter(encrypt.AES(masterKey));
          return dataEncrypter.decrypt(payload, iv: iv);
        }
      }

      return null;
    } catch (e) {
      debugPrint("Decryption failed: $e");
      return null;
    }
  }

  /// Wrap the master key using a derived key
  static String _wrapKey(Uint8List masterKey, encrypt.Key derivedKey) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(derivedKey));
    final encrypted = encrypter.encryptBytes(masterKey, iv: iv);
    return base64.encode(Uint8List.fromList([...iv.bytes, ...encrypted.bytes]));
  }

  /// Unwrap the master key using a derived key
  static Uint8List? _unwrapKey(
    String wrappedKeyBase64,
    encrypt.Key derivedKey,
  ) {
    try {
      final combined = base64.decode(wrappedKeyBase64);
      if (combined.length < 16) return null;

      final iv = encrypt.IV(combined.sublist(0, 16));
      final ciphertext = encrypt.Encrypted(combined.sublist(16));

      final encrypter = encrypt.Encrypter(encrypt.AES(derivedKey));
      return Uint8List.fromList(encrypter.decryptBytes(ciphertext, iv: iv));
    } catch (_) {
      return null;
    }
  }

  /// Generate a human-readable recovery phrase (6 blocks of 4-4 chars)
  static String generateRecoveryCode() {
    final random = encrypt.IV.fromSecureRandom(24);
    final hexString = random.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();

    final blocks = <String>[];
    for (var i = 0; i < 48; i += 8) {
      final block = hexString.substring(i, i + 8);
      blocks.add("${block.substring(0, 4)}-${block.substring(4)}");
    }
    return blocks.join(' ');
  }
}
