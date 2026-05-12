// File: lib/features/chat/presentation/chat_room_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/storage_service.dart';
import '../../auth/providers/providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/reply_preview.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen>
    with TickerProviderStateMixin {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final _recorder = AudioRecorder();
  final _picker = ImagePicker();

  MessageModel? _replyTo;
  bool _isRecording = false;
  bool _isSelfDestruct = false;
  bool _showActions = false;
  String? _recordingPath;
  double _recordingSeconds = 0;

  late AnimationController _micSlideCtrl;
  late Animation<double> _micSlide;

  @override
  void initState() {
    super.initState();
    _micSlideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _micSlide = Tween<double>(begin: 0, end: -80)
        .animate(CurvedAnimation(parent: _micSlideCtrl, curve: Curves.easeOut));
    _markRead();
  }

  Future<void> _markRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(firestoreServiceProvider).markMessagesRead(
        widget.chatId, user.id);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _recorder.dispose();
    _micSlideCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    _msgCtrl.clear();

    final msg = MessageModel(
      id: '',
      senderId: user.id,
      senderName: user.displayName,
      senderAvatar: user.avatarUrl,
      type: MessageType.text,
      text: text,
      replyToId: _replyTo?.id,
      replyToText: _replyTo?.text,
      replyToSender: _replyTo?.senderName,
      createdAt: DateTime.now(),
    );
    setState(() => _replyTo = null);
    await ref.read(firestoreServiceProvider).sendMessage(
      chatId: widget.chatId,
      message: msg,
      otherUserId: widget.otherUserId,
    );
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    for (final f in files) {
      final file = File(f.path);
      final url = await ref.read(storageServiceProvider).uploadChatMedia(
        chatId: widget.chatId,
        file: file,
        type: 'image',
      );
      await ref.read(firestoreServiceProvider).sendMessage(
        chatId: widget.chatId,
        message: MessageModel(
          id: '',
          senderId: user.id,
          senderName: user.displayName,
          senderAvatar: user.avatarUrl,
          type: MessageType.image,
          mediaUrl: url,
          createdAt: DateTime.now(),
        ),
        otherUserId: widget.otherUserId,
      );
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;
    final dir = await getTemporaryDirectory();
    _recordingPath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordingPath!,
    );
    setState(() { _isRecording = true; _recordingSeconds = 0; });
    HapticFeedback.mediumImpact();
    _micSlideCtrl.forward();
  }

  Future<void> _stopRecording({bool send = true, bool selfDestruct = false}) async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    _micSlideCtrl.reverse();
    HapticFeedback.lightImpact();
    if (!send || path == null) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final file = File(path);
    final url = await ref.read(storageServiceProvider).uploadChatMedia(
      chatId: widget.chatId,
      file: file,
      type: 'audio',
    );
    await ref.read(firestoreServiceProvider).sendMessage(
      chatId: widget.chatId,
      message: MessageModel(
        id: '',
        senderId: user.id,
        senderName: user.displayName,
        senderAvatar: user.avatarUrl,
        type: MessageType.audio,
        mediaUrl: url,
        isSelfDestruct: selfDestruct,
        audioDuration: _recordingSeconds.toInt(),
        createdAt: DateTime.now(),
      ),
      otherUserId: widget.otherUserId,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();
    final msgsAsync = ref.watch(messagesProvider(widget.chatId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(user),
          Expanded(
            child: msgsAsync.when(
              data: (msgs) => _buildMessageList(msgs, user),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.neonRed),
              ),
              error: (e, _) => Center(
                child: Text(e.toString(),
                    style: const TextStyle(color: AppColors.neonRed)),
              ),
            ),
          ),
          if (_replyTo != null)
            ReplyPreview(
              message: _replyTo!,
              onCancel: () => setState(() => _replyTo = null),
            ),
          _buildInputBar(user),
        ],
      ),
    );
  }

  Widget _buildAppBar(UserModel user) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 12,
        right: 12,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        border: const Border(
            bottom: BorderSide(color: AppColors.glassBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.silver, size: 20),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {},
            child: _buildOtherAvatar(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  StreamBuilder<UserModel?>(
                    stream: ref
                        .read(firestoreServiceProvider)
                        .streamUser(widget.otherUserId),
                    builder: (ctx, snap) {
                      final other = snap.data;
                      if (other == null) return const SizedBox();
                      return Text(
                        other.isOnline ? 'متصل الآن' : 'غير متصل',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: other.isOnline
                              ? AppColors.online
                              : AppColors.textMuted,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.videocam_outlined,
                color: AppColors.silver, size: 22),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.call_outlined,
                color: AppColors.silver, size: 22),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.more_vert_rounded,
                color: AppColors.silver, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: ClipOval(
        child: widget.otherUserAvatar != null
            ? CachedNetworkImage(
                imageUrl: widget.otherUserAvatar!,
                fit: BoxFit.cover,
              )
            : Container(
                color: AppColors.surfaceLight,
                child: Center(
                  child: Text(
                    widget.otherUserName.isNotEmpty
                        ? widget.otherUserName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.silver),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMessageList(List<MessageModel> msgs, UserModel user) {
    if (msgs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonRed.withOpacity(0.07),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.neonRed, size: 36),
            ),
            const SizedBox(height: 14),
            const Text(
              'لا توجد رسائل بعد\nابدأ المحادثة!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.6),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: msgs.length,
      itemBuilder: (ctx, i) {
        final msg = msgs[i];
        final isMe = msg.senderId == user.id;
        return MessageBubble(
          message: msg,
          isMe: isMe,
          bubbleShape: ref.watch(bubbleShapeProvider),
          onReply: () => setState(() => _replyTo = msg),
          onDelete: () => _deleteMessage(msg, isMe),
          onCopy: () {
            if (msg.text != null) {
              Clipboard.setData(ClipboardData(text: msg.text!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ الرسالة')),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _deleteMessage(MessageModel msg, bool isMe) async {
    if (!isMe) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('حذف الرسالة',
            style: TextStyle(
                fontFamily: 'Cairo', color: AppColors.textPrimary)),
        content: const Text('اختر طريقة الحذف',
            style: TextStyle(
                fontFamily: 'Cairo', color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'me'),
            child: const Text('حذف لي فقط',
                style: TextStyle(
                    fontFamily: 'Cairo', color: AppColors.silverDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'all'),
            child: const Text('حذف للجميع',
                style: TextStyle(
                    fontFamily: 'Cairo', color: AppColors.neonRed)),
          ),
        ],
      ),
    );
    if (choice == null) return;
    await ref.read(firestoreServiceProvider).deleteMessage(
      chatId: widget.chatId,
      messageId: msg.id,
      deleteForAll: choice == 'all',
    );
  }

  Widget _buildInputBar(UserModel user) {
    return Container(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        border: const Border(
            top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attach
          GestureDetector(
            onTap: _sendImage,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.glassFill,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.attach_file_rounded,
                  color: AppColors.silver, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          // Text Field
          Expanded(
            child: GlassContainer(
              borderRadius: 20,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        controller: _msgCtrl,
                        maxLines: null,
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: AppStrings.typeMessage,
                          hintStyle: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: AppColors.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                    ),
                  ),
                  // Sticker
                  GestureDetector(
                    onTap: () {},
                    child: const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.emoji_emotions_outlined,
                          color: AppColors.silverDim, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send / Mic button
          AnimatedBuilder(
            animation: _msgCtrl,
            builder: (ctx, _) {
              final hasText = _msgCtrl.text.trim().isNotEmpty;
              return GestureDetector(
                onTap: hasText ? _sendText : null,
                onLongPressStart: hasText
                    ? null
                    : (_) => _startRecording(),
                onLongPressEnd: hasText
                    ? null
                    : (d) {
                        // Swipe up = self-destruct
                        final dy = d.globalPosition.dy;
                        final threshold =
                            MediaQuery.of(context).size.height * 0.75;
                        _stopRecording(
                          send: true,
                          selfDestruct: dy < threshold,
                        );
                      },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.neonRed,
                        AppColors.darkRed,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonRed.withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    hasText
                        ? Icons.send_rounded
                        : (_isRecording
                            ? Icons.stop_rounded
                            : Icons.mic_rounded),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
