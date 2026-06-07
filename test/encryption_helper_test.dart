import 'package:flutter_test/flutter_test.dart';
import 'package:done_today/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper Tests', () {
    const password = 'test-password-123';
    const recoveryPhrase =
        'ABCD-EFGH IJKL-MNOP QRST-UVWX YZ12-3456 7890-ABCD EFGH-IJKL';
    const originalData = '{"key": "value", "secret": "top-secret-data"}';

    test('Encryption and Decryption with Password', () {
      final encrypted = EncryptionHelper.encryptData(
        originalData,
        password,
        recoveryPhrase,
      );

      expect(encrypted['payload'], isNotNull);
      expect(encrypted['v'], equals(5));

      final decrypted = EncryptionHelper.decryptData(encrypted, password);
      expect(decrypted, equals(originalData));
    });

    test('Encryption and Decryption with Recovery Phrase', () {
      final encrypted = EncryptionHelper.encryptData(
        originalData,
        password,
        recoveryPhrase,
      );

      final decrypted = EncryptionHelper.decryptData(encrypted, recoveryPhrase);
      expect(decrypted, equals(originalData));
    });

    test('Decryption fails with wrong password', () {
      final encrypted = EncryptionHelper.encryptData(
        originalData,
        password,
        recoveryPhrase,
      );

      final decrypted = EncryptionHelper.decryptData(
        encrypted,
        'wrong-password',
      );
      expect(decrypted, isNull);
    });

    test('Recovery phrase generation works', () {
      final code = EncryptionHelper.generateRecoveryCode();
      expect(code, isNotEmpty);
      expect(code.split(' ').length, equals(6));
    });
  });
}
