// lib/services/encryption_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyPrefix = 'chat_key_';

  // ── Generate chat-specific AES key ───────────────────
  static String _deriveChatKey(String chatId, String userId) {
    final raw = '$chatId:$userId:ilya-chat-2026';
    final bytes = utf8.encode(raw);
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }

  // ── Get or create key for chat ───────────────────────
  static Future<enc.Key> _getKey(String chatId, String userId) async {
    final storageKey = '$_keyPrefix${chatId}_$userId';
    String? stored = await _storage.read(key: storageKey);
    if (stored == null) {
      stored = _deriveChatKey(chatId, userId);
      await _storage.write(key: storageKey, value: stored);
    }
    final keyBytes = base64Decode(stored);
    return enc.Key(Uint8List.fromList(keyBytes.take(32).toList()));
  }

  // ── Encrypt message ───────────────────────────────────
  static Future<String> encrypt({
    required String plainText,
    required String chatId,
    required String userId,
  }) async {
    try {
      final key = await _getKey(chatId, userId);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      // Combine IV + ciphertext
      return '${base64Encode(iv.bytes)}:${encrypted.base64}';
    } catch (_) {
      return plainText; // Fallback: no encryption
    }
  }

  // ── Decrypt message ───────────────────────────────────
  static Future<String> decrypt({
    required String cipherText,
    required String chatId,
    required String userId,
  }) async {
    try {
      if (!cipherText.contains(':')) return cipherText;
      final parts = cipherText.split(':');
      if (parts.length < 2) return cipherText;
      final iv = enc.IV(base64Decode(parts[0]));
      final cipher = enc.Encrypted(base64Decode(parts[1]));
      final key = await _getKey(chatId, userId);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(cipher, iv: iv);
    } catch (_) {
      return cipherText; // Fallback: return raw
    }
  }

  // ── Hash password ─────────────────────────────────────
  static String hashPassword(String password) {
    final bytes = utf8.encode('$password:ilya-chat-salt-2026');
    return sha256.convert(bytes).toString();
  }

  // ── Generate device fingerprint ───────────────────────
  static Future<String> deviceFingerprint() async {
    final stored = await _storage.read(key: 'device_fingerprint');
    if (stored != null) return stored;
    final random = enc.IV.fromSecureRandom(16);
    final fp = base64Encode(random.bytes);
    await _storage.write(key: 'device_fingerprint', value: fp);
    return fp;
  }

  // ── Secure delete all keys ────────────────────────────
  static Future<void> clearAllKeys() async {
    await _storage.deleteAll();
  }
}
