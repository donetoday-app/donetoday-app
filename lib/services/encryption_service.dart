import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static Key? _key;
  static IV? _iv;

  /// Initializes the encryption key and IV based on user ID.
  /// This ensures the key/IV is consistent for the same user across devices.
  void init(String userId) {
    if (userId.isEmpty) return;
    
    // Generate a 32-byte key using SHA-256 hash of the user ID
    final keyBytes = utf8.encode(userId);
    final keyDigest = sha256.convert(keyBytes);
    _key = Key(Uint8List.fromList(keyDigest.bytes));

    // Generate a deterministic 16-byte IV using a hash of the user ID + salt
    // MD5 provides exactly 16 bytes (128 bits) needed for the AES IV
    final ivBytes = utf8.encode(userId + "_dt_iv_salt_v1");
    final ivDigest = md5.convert(ivBytes);
    _iv = IV(Uint8List.fromList(ivDigest.bytes));
  }

  bool get isInitialized => _key != null && _iv != null;

  /// Encrypts a plain text string.
  String encrypt(String text) {
    if (text.isEmpty) return text;
    if (_key == null || _iv == null) return text;

    final encrypter = Encrypter(AES(_key!));
    final encrypted = encrypter.encrypt(text, iv: _iv!);
    return encrypted.base64;
  }

  /// Decrypts an encrypted base64 string.
  /// Returns null if decryption fails or service not initialized.
  String? decrypt(String encryptedBase64) {
    if (encryptedBase64.isEmpty) return encryptedBase64;
    
    if (_key == null || _iv == null) {
      return null;
    }

    try {
      final encrypter = Encrypter(AES(_key!));
      final decrypted = encrypter.decrypt64(encryptedBase64, iv: _iv!);
      return decrypted;
    } catch (e) {
      // Decryption failed (e.g. data encrypted with different key or is plain text)
      // Return original to allow fallback to plain text
      return encryptedBase64;
    }
  }

  /// Helper to encrypt sensitive fields in a map
  Map<String, dynamic> encryptMap(
    Map<String, dynamic> map,
    List<String> fields,
  ) {
    if (!isInitialized) return map;

    final result = Map<String, dynamic>.from(map);
    for (var field in fields) {
      if (result.containsKey(field) && result[field] is String) {
        result[field] = encrypt(result[field]);
      }
    }
    return result;
  }

  /// Helper to decrypt sensitive fields in a map
  Map<String, dynamic> decryptMap(
    Map<String, dynamic> map,
    List<String> fields,
  ) {
    if (!isInitialized) return map;

    final result = Map<String, dynamic>.from(map);
    for (var field in fields) {
      if (result.containsKey(field) && result[field] is String) {
        result[field] = decrypt(result[field]);
      }
    }
    return result;
  }
}
