// lib/core/extensions/context_ext.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension ContextExt on BuildContext {
  double get sw => MediaQuery.of(this).size.width;
  double get sh => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  ThemeData get theme => Theme.of(this);
  bool get isRTL => Directionality.of(this) == TextDirection.rtl;

  void showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        backgroundColor:
            error ? const Color(0xFFFF0033) : const Color(0xFF12121A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void copyToClipboard(String text, {String? message}) {
    Clipboard.setData(ClipboardData(text: text));
    showSnack(message ?? 'تم النسخ');
  }

  Future<bool?> confirm({required String title, required String body}) {
    return showDialog<bool>(
      context: this,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF12121A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
                fontWeight: FontWeight.w700)),
        content: Text(body,
            style: const TextStyle(
                fontFamily: 'Cairo', color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(this, false),
            child: const Text('إلغاء',
                style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(this, true),
            child: const Text('تأكيد',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Color(0xFFFF0033),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
