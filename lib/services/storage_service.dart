// File: lib/services/storage_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // ── Upload Avatar ────────────────────────────────────
  Future<String> uploadAvatar(String userId, File file) async {
    final ext = file.path.split('.').last;
    final ref = _storage.ref('avatars/$userId.$ext');
    final task = await ref.putFile(file, SettableMetadata(contentType: 'image/$ext'));
    return await task.ref.getDownloadURL();
  }

  // ── Upload Chat Media ────────────────────────────────
  Future<String> uploadChatMedia({
    required String chatId,
    required File file,
    required String type, // 'image', 'video', 'audio', 'file'
  }) async {
    final id = _uuid.v4();
    final ext = file.path.split('.').last;
    final ref = _storage.ref('chats/$chatId/$type/$id.$ext');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  // ── Upload Bytes (for web) ───────────────────────────
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final ref = _storage.ref(path);
    final task = await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return await task.ref.getDownloadURL();
  }

  // ── Upload Story Media ───────────────────────────────
  Future<String> uploadStoryMedia({
    required String userId,
    required File file,
    required bool isVideo,
  }) async {
    final id = _uuid.v4();
    final ext = file.path.split('.').last;
    final type = isVideo ? 'video' : 'image';
    final ref = _storage.ref('stories/$userId/$id.$ext');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: '$type/$ext'),
    );
    return await task.ref.getDownloadURL();
  }

  // ── Delete File ───────────────────────────────────────
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }

  // ── Upload Progress Stream ────────────────────────────
  Stream<double> uploadWithProgress({
    required String path,
    required File file,
  }) {
    final ref = _storage.ref(path);
    final task = ref.putFile(file);
    return task.snapshotEvents.map(
      (snap) => snap.bytesTransferred / snap.totalBytes,
    );
  }
}
