// File: lib/core/utils/validators.dart
class AppValidators {
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
    if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'اسم المستخدم مطلوب';
    if (value.length < 2) return 'اسم المستخدم يجب أن يكون حرفين على الأقل';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'اسم المستخدم يحتوي على أحرف غير مسموح بها';
    }
    return null;
  }

  static String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) return 'الاسم مطلوب';
    if (value.length < 2) return 'الاسم يجب أن يكون حرفين على الأقل';
    return null;
  }

  static String? validateUserId(String? value) {
    if (value == null || value.isEmpty) return 'الـ ID مطلوب';
    final stripped = value.replaceAll('-', '').trim();
    if (!RegExp(r'^\d{12}$').hasMatch(stripped)) {
      return 'الـ ID يجب أن يكون 12 رقماً';
    }
    return null;
  }

  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value); if (uri == null || !uri.hasScheme) return 'رابط غير صحيح';
    return null;
  }
}

// File: lib/core/utils/link_detector.dart
enum LinkPlatform {
  facebook,
  instagram,
  twitter,
  youtube,
  tiktok,
  snapchat,
  linkedin,
  github,
  telegram,
  discord,
  twitch,
  reddit,
  website,
  other,
}

class LinkDetector {
  static LinkPlatform detect(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('facebook.com') || lower.contains('fb.com')) {
      return LinkPlatform.facebook;
    }
    if (lower.contains('instagram.com')) return LinkPlatform.instagram;
    if (lower.contains('twitter.com') || lower.contains('x.com')) {
      return LinkPlatform.twitter;
    }
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return LinkPlatform.youtube;
    }
    if (lower.contains('tiktok.com')) return LinkPlatform.tiktok;
    if (lower.contains('snapchat.com')) return LinkPlatform.snapchat;
    if (lower.contains('linkedin.com')) return LinkPlatform.linkedin;
    if (lower.contains('github.com')) return LinkPlatform.github;
    if (lower.contains('t.me') || lower.contains('telegram')) {
      return LinkPlatform.telegram;
    }
    if (lower.contains('discord')) return LinkPlatform.discord;
    if (lower.contains('twitch.tv')) return LinkPlatform.twitch;
    if (lower.contains('reddit.com')) return LinkPlatform.reddit;
    if (lower.startsWith('http')) return LinkPlatform.website;
    return LinkPlatform.other;
  }

  static String platformLabel(LinkPlatform p) {
    switch (p) {
      case LinkPlatform.facebook:
        return 'Facebook';
      case LinkPlatform.instagram:
        return 'Instagram';
      case LinkPlatform.twitter:
        return 'X (Twitter)';
      case LinkPlatform.youtube:
        return 'YouTube';
      case LinkPlatform.tiktok:
        return 'TikTok';
      case LinkPlatform.snapchat:
        return 'Snapchat';
      case LinkPlatform.linkedin:
        return 'LinkedIn';
      case LinkPlatform.github:
        return 'GitHub';
      case LinkPlatform.telegram:
        return 'Telegram';
      case LinkPlatform.discord:
        return 'Discord';
      case LinkPlatform.twitch:
        return 'Twitch';
      case LinkPlatform.reddit:
        return 'Reddit';
      case LinkPlatform.website:
        return 'Website';
      default:
        return 'رابط';
    }
  }
}
