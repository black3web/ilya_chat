// File: lib/core/utils/id_generator.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class IdGenerator {
  static final Random _rng = Random.secure();

  /// Generates a unique 12-digit numeric ID.
  /// Checks Firestore to guarantee no collision.
  static Future<String> generateUniqueId() async {
    while (true) {
      final id = _generateRaw();
      if (id == '000000000001') continue; // reserved for superuser
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .get();
      if (!doc.exists) return id;
    }
  }

  static String _generateRaw() {
    // First digit cannot be 0 to avoid ID starting with 0
    final first = _rng.nextInt(9) + 1; // 1-9
    final rest = List.generate(11, (_) => _rng.nextInt(10)).join();
    return '$first$rest';
  }

  /// Formats a 12-digit ID for display: XXXX-XXXX-XXXX
  static String formatId(String id) {
    if (id.length != 12) return id;
    return '${id.substring(0, 4)}-${id.substring(4, 8)}-${id.substring(8, 12)}';
  }

  /// Strips formatting from formatted ID
  static String stripId(String formattedId) {
    return formattedId.replaceAll('-', '').trim();
  }

  /// Validate 12-digit numeric ID
  static bool isValidId(String id) {
    final stripped = stripId(id);
    return RegExp(r'^\d{12}$').hasMatch(stripped);
  }
}
