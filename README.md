# ILYA-Chat 🔴

تطبيق مراسلة ضخم يجمع بين تيليجرام، ديسكورد، وواتساب.

---

## 📁 هيكل المشروع

```
ilya_chat/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── router.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   └── app_strings.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── utils/
│   │   │   ├── id_generator.dart
│   │   │   └── validators.dart
│   │   └── widgets/
│   │       ├── glass_container.dart
│   │       └── neon_widgets.dart
│   ├── models/
│   │   └── user_model.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   └── storage_service.dart
│   └── features/
│       ├── auth/
│       │   ├── providers/providers.dart
│       │   └── presentation/
│       │       ├── splash_screen.dart
│       │       ├── language_screen.dart
│       │       ├── login_screen.dart
│       │       └── register_screen.dart
│       ├── home/
│       │   ├── presentation/home_screen.dart
│       │   └── widgets/
│       │       ├── chat_list_tile.dart
│       │       ├── story_ring.dart
│       │       └── glass_drawer.dart
│       ├── chat/
│       │   ├── presentation/chat_room_screen.dart
│       │   └── widgets/
│       │       ├── message_bubble.dart
│       │       └── reply_preview.dart
│       ├── profile/
│       │   └── presentation/profile_screen.dart
│       ├── groups/
│       │   └── presentation/group_screen.dart
│       ├── channels/
│       │   └── presentation/channel_screen.dart
│       └── admin/
│           └── presentation/admin_panel.dart
├── android/
├── ios/
├── web/
├── firestore.rules
├── firestore.indexes.json
├── storage.rules
├── firebase.json
└── pubspec.yaml
```

---

## 🚀 تشغيل المشروع

### 1. تثبيت الحزم
```bash
flutter pub get
```

### 2. تشغيل Android
```bash
flutter run -d android
```

### 3. بناء APK
```bash
flutter build apk --release
# الملف في: build/app/outputs/flutter-apk/app-release.apk
```

### 4. بناء iOS
```bash
flutter build ios --release
```

### 5. بناء Web
```bash
flutter build web --release
```

### 6. نشر على Firebase Hosting
```bash
firebase deploy --only hosting
```

### 7. رفع قواعد Firestore
```bash
firebase deploy --only firestore
```

---

## 🔑 بيانات حساب المبرمج (Superuser)

| الحقل | القيمة |
|-------|--------|
| الاسم | المبرمج إيليا |
| ID | 000000000001 |
| اليوزر | a1 |
| الباسورد | vgty085690vgty |

---

## 🏗️ هيكل Firestore

```
/users/{userId}          ← بيانات المستخدم (الـ ID هو اسم المستند)
/uid_map/{firebaseUID}   ← ربط Firebase UID بالـ ID المخصص
/chats/{chatId}/
  messages/{msgId}       ← رسائل المحادثات الخاصة
/groups/{groupId}/
  messages/{msgId}       ← رسائل المجموعات
/channels/{channelId}/
  messages/{msgId}       ← رسائل القنوات
/stories/{storyId}       ← القصص (TTL تلقائي 24h)
/support_tickets/{id}    ← بلاغات الدعم الفني
```

---

## ✅ المتطلبات

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Firebase Project: ilya-chat
- Android: minSdk 21+
- iOS: 13.0+

---

© 2024 المبرمج إيليا - جميع الحقوق محفوظة
