// File: lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/id_generator.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentFirebaseUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Initialize Superuser ────────────────────────────
  Future<void> initSuperuser() async {
    const superId = AppStrings.superuserId;
    final doc = await _db.collection('users').doc(superId).get();
    if (doc.exists) return;

    // Create superuser Firebase Auth account
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: AppStrings.superuserEmail,
        password: AppStrings.superuserPassword,
      );
      await _db.collection('users').doc(superId).set({
        'username': AppStrings.superuserUsername,
        'displayName': AppStrings.superuserName,
        'email': AppStrings.superuserEmail,
        'avatarUrl': null,
        'bio': 'مبرمج التطبيق ومطوره',
        'links': [],
        'isOnline': false,
        'lastSeen': null,
        'isSuperuser': true,
        'isBanned': false,
        'profileGradientIndex': 3,
        'profileGradientDirection': 0,
        'fcmToken': null,
        'createdAt': Timestamp.now(),
      });

      // Map firebase UID to our custom ID
      await _db.collection('uid_map').doc(cred.user!.uid).set({
        'customId': superId,
      });

      // Create official channel
      await _createOfficialChannel(superId);
      await _auth.signOut();
    } on Exception {
      // Superuser already exists - safe to ignore
    }
  }

  Future<void> _createOfficialChannel(String ownerId) async {
    final channelRef =
        _db.collection('channels').doc(AppStrings.officialChannelId);
    final exists = await channelRef.get();
    if (exists.exists) return;

    await channelRef.set({
      'name': AppStrings.officialChannelName,
      'description': 'القناة الرسمية لتطبيق ILYA-Chat',
      'avatarUrl': null,
      'ownerId': ownerId,
      'adminIds': [ownerId],
      'subscriberIds': [ownerId],
      'lastMessage': null,
      'lastMessageTime': null,
      'createdAt': Timestamp.now(),
      'isOfficial': true,
    });
  }

  // ── Register ────────────────────────────────────────
  Future<UserModel> register({
    required String displayName,
    required String username,
    required String password,
  }) async {
    // Validate username uniqueness
    final usernameQuery = await _db
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    if (usernameQuery.docs.isNotEmpty) {
      throw Exception(AppStrings.errorUsernameExists);
    }

    // Generate unique 12-digit ID
    final customId = await IdGenerator.generateUniqueId();

    // Create internal email from custom ID
    final email = '$customId@ilya-chat.internal';

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final now = DateTime.now();
    final user = UserModel(
      id: customId,
      username: username.toLowerCase(),
      displayName: displayName,
      email: email,
      createdAt: now,
    );

    // Save to Firestore
    await _db.collection('users').doc(customId).set(user.toMap());

    // Map Firebase UID → custom ID
    await _db
        .collection('uid_map')
        .doc(cred.user!.uid)
        .set({'customId': customId});

    // Auto-subscribe to official channel
    await _db
        .collection('channels')
        .doc(AppStrings.officialChannelId)
        .update({
      'subscriberIds': FieldValue.arrayUnion([customId]),
    });

    return user;
  }

  // ── Login with custom ID ────────────────────────────
  Future<UserModel> loginWithId({
    required String customId,
    required String password,
  }) async {
    // Check if it's superuser with ID '1' or '000000000001'
    final normalizedId = customId.trim().padLeft(12, '0');

    // Construct email
    String email;
    if (normalizedId == AppStrings.superuserId &&
        password == AppStrings.superuserPassword) {
      email = AppStrings.superuserEmail;
    } else {
      email = '$normalizedId@ilya-chat.internal';
    }

    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Get custom ID from uid_map
    final uidDoc =
        await _db.collection('uid_map').doc(cred.user!.uid).get();
    final resolvedId =
        uidDoc.exists ? uidDoc.data()!['customId'] as String : normalizedId;

    final userDoc = await _db.collection('users').doc(resolvedId).get();
    if (!userDoc.exists) throw Exception(AppStrings.errorUserNotFound);

    final user = UserModel.fromMap(userDoc.data()!, resolvedId);
    if (user.isBanned) {
      await _auth.signOut();
      throw Exception('تم حظر هذا الحساب');
    }

    // Update online status
    await _db.collection('users').doc(resolvedId).update({
      'isOnline': true,
      'lastSeen': Timestamp.now(),
    });

    return user;
  }

  // ── Login with username ─────────────────────────────
  Future<UserModel> loginWithUsername({
    required String username,
    required String password,
  }) async {
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) throw Exception(AppStrings.errorUserNotFound);

    final customId = query.docs.first.id;
    return loginWithId(customId: customId, password: password);
  }

  // ── Logout ──────────────────────────────────────────
  Future<void> logout(String userId) async {
    await _db.collection('users').doc(userId).update({
      'isOnline': false,
      'lastSeen': Timestamp.now(),
    });
    await _auth.signOut();
  }

  // ── Get current user data ───────────────────────────
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final uidDoc =
        await _db.collection('uid_map').doc(firebaseUser.uid).get();
    if (!uidDoc.exists) return null;

    final customId = uidDoc.data()!['customId'] as String;
    final userDoc = await _db.collection('users').doc(customId).get();
    if (!userDoc.exists) return null;

    return UserModel.fromMap(userDoc.data()!, customId);
  }

  // ── Stream current user ─────────────────────────────
  Stream<UserModel?> streamCurrentUser(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snap) => snap.exists
            ? UserModel.fromMap(snap.data()!, snap.id)
            : null);
  }

  // ── Update FCM token ────────────────────────────────
  Future<void> updateFcmToken(String userId, String token) async {
    await _db.collection('users').doc(userId).update({'fcmToken': token});
  }
}
