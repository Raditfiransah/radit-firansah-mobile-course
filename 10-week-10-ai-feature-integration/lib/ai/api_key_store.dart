import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class ApiKeyStore {
  Future<String?> read();
  Future<void> write(String key);
  Future<void> clear();
}

class SecureApiKeyStore implements ApiKeyStore {
  const SecureApiKeyStore();

  static const _storageKey = 'ai_api_key';
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _storageKey);

  @override
  Future<void> write(String key) =>
      _storage.write(key: _storageKey, value: key.trim());

  @override
  Future<void> clear() => _storage.delete(key: _storageKey);
}
