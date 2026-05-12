// lib/services/media_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class MediaService {
  static final _picker = ImagePicker();
  static const _uuid = Uuid();

  // ── Pick single image ────────────────────────────────
  static Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    int quality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    return file != null ? File(file.path) : null;
  }

  // ── Pick multiple images ─────────────────────────────
  static Future<List<File>> pickMultipleImages({int quality = 85}) async {
    final files = await _picker.pickMultiImage(imageQuality: quality);
    return files.map((f) => File(f.path)).toList();
  }

  // ── Pick video ───────────────────────────────────────
  static Future<File?> pickVideo({
    ImageSource source = ImageSource.gallery,
  }) async {
    final file = await _picker.pickVideo(source: source);
    return file != null ? File(file.path) : null;
  }

  // ── Generate temp path ────────────────────────────────
  static Future<String> tempPath(String ext) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/${_uuid.v4()}.$ext';
  }

  // ── Get file size in MB ───────────────────────────────
  static double fileSizeMB(File file) {
    return file.lengthSync() / (1024 * 1024);
  }

  // ── Format file size ─────────────────────────────────
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ── Get file extension ────────────────────────────────
  static String fileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }

  // ── Check if image ────────────────────────────────────
  static bool isImage(String path) {
    final ext = fileExtension(path);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext);
  }

  // ── Check if video ────────────────────────────────────
  static bool isVideo(String path) {
    final ext = fileExtension(path);
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  }

  // ── Check if audio ────────────────────────────────────
  static bool isAudio(String path) {
    final ext = fileExtension(path);
    return ['mp3', 'm4a', 'wav', 'ogg', 'aac'].contains(ext);
  }

  // ── Format audio duration ─────────────────────────────
  static String formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Delete temp files ─────────────────────────────────
  static Future<void> cleanTemp() async {
    try {
      final dir = await getTemporaryDirectory();
      final files = dir.listSync();
      for (final f in files) {
        if (f is File) {
          final age = DateTime.now().difference(
              (await f.stat()).modified);
          if (age.inHours > 24) await f.delete();
        }
      }
    } catch (_) {}
  }
}
