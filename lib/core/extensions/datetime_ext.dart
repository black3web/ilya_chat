// lib/core/extensions/datetime_ext.dart
extension DateTimeExt on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  bool get isThisWeek {
    return DateTime.now().difference(this).inDays < 7;
  }

  String get chatTime {
    if (isToday) {
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
    if (isYesterday) return 'أمس';
    if (isThisWeek) {
      const days = ['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت'];
      return days[weekday % 7];
    }
    return '${day}/${month}/${year}';
  }

  String get messageTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String get fullDate {
    return '$day/$month/$year ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String get relativeTime {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
    return fullDate;
  }
}

// lib/core/extensions/string_ext.dart
extension StringExt on String {
  String get initials {
    final parts = trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get isValidUrl => Uri.tryParse(this)?.hasScheme ?? false;

  bool get isArabic => RegExp(r'[\u0600-\u06FF]').hasMatch(this);

  String get stripHtml => replaceAll(RegExp(r'<[^>]*>'), '');

  String truncate(int length) =>
      this.length > length ? '${substring(0, length)}...' : this;

  String get formatted12DigitId {
    if (length != 12) return this;
    return '${substring(0, 4)}-${substring(4, 8)}-${substring(8, 12)}';
  }
}
