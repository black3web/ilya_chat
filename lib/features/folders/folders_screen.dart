// lib/features/folders/folders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/neon_widgets.dart';
import '../../models/user_model.dart';
import '../auth/providers/providers.dart';

// Folder model
class ChatFolder {
  final String id;
  final String name;
  final String icon;
  final List<String> chatIds;
  final int colorIndex;

  const ChatFolder({
    required this.id,
    required this.name,
    required this.icon,
    this.chatIds = const [],
    this.colorIndex = 0,
  });

  factory ChatFolder.fromJson(Map<String, dynamic> j) => ChatFolder(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        icon: j['icon'] ?? '📁',
        chatIds: List<String>.from(j['chatIds'] ?? []),
        colorIndex: j['colorIndex'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'chatIds': chatIds,
        'colorIndex': colorIndex,
      };

  ChatFolder copyWith({
    String? name,
    String? icon,
    List<String>? chatIds,
    int? colorIndex,
  }) {
    return ChatFolder(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      chatIds: chatIds ?? this.chatIds,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }
}

final _foldersProvider =
    StateNotifierProvider<FoldersNotifier, List<ChatFolder>>(
        (ref) => FoldersNotifier());

class FoldersNotifier extends StateNotifier<List<ChatFolder>> {
  FoldersNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('chat_folders');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      state = list
          .map((j) => ChatFolder.fromJson(j as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'chat_folders', jsonEncode(state.map((f) => f.toJson()).toList()));
  }

  Future<void> addFolder(ChatFolder folder) async {
    state = [...state, folder];
    await _save();
  }

  Future<void> updateFolder(ChatFolder folder) async {
    state = state.map((f) => f.id == folder.id ? folder : f).toList();
    await _save();
  }

  Future<void> deleteFolder(String id) async {
    state = state.where((f) => f.id != id).toList();
    await _save();
  }

  Future<void> addChatToFolder(String folderId, String chatId) async {
    state = state.map((f) {
      if (f.id == folderId && !f.chatIds.contains(chatId)) {
        return f.copyWith(chatIds: [...f.chatIds, chatId]);
      }
      return f;
    }).toList();
    await _save();
  }

  Future<void> removeChatFromFolder(String folderId, String chatId) async {
    state = state.map((f) {
      if (f.id == folderId) {
        return f.copyWith(
            chatIds: f.chatIds.where((id) => id != chatId).toList());
      }
      return f;
    }).toList();
    await _save();
  }
}

class FoldersScreen extends ConsumerStatefulWidget {
  const FoldersScreen({super.key});

  @override
  ConsumerState<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends ConsumerState<FoldersScreen> {
  final _nameCtrl = TextEditingController();
  String _selectedIcon = '📁';
  int _selectedColor = 0;

  static const _folderIcons = [
    '📁', '💬', '🔥', '⭐', '👥', '📢', '🔔', '❤️',
    '💼', '🏠', '🎮', '📚', '🎵', '🏋️', '✈️', '🎨',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(_foldersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(),
          if (folders.isEmpty)
            Expanded(child: _buildEmpty())
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: folders.length,
                itemBuilder: (ctx, i) => _FolderTile(
                  folder: folders[i],
                  onDelete: () => ref
                      .read(_foldersProvider.notifier)
                      .deleteFolder(folders[i].id),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              colors: [AppColors.neonRed, AppColors.darkRed]),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonRed.withOpacity(0.4),
              blurRadius: 16,
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.create_new_folder_outlined,
              color: Colors.white, size: 22),
          onPressed: _showCreateDialog,
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
            bottom: BorderSide(color: AppColors.glassBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.silver, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'المجلدات',
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonRed.withOpacity(0.08),
              border: Border.all(
                  color: AppColors.neonRed.withOpacity(0.2), width: 1),
            ),
            child: const Icon(Icons.folder_outlined,
                color: AppColors.neonRed, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد مجلدات',
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'أنشئ مجلداً لتنظيم محادثاتك',
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    _nameCtrl.clear();
    _selectedIcon = '📁';
    _selectedColor = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
                top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.silverDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'مجلد جديد',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              // Icon picker
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _folderIcons.length,
                  itemBuilder: (_, i) {
                    final icon = _folderIcons[i];
                    final selected = _selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setModalState(
                          () => _selectedIcon = icon),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: selected
                              ? AppColors.neonRed.withOpacity(0.15)
                              : AppColors.glassFill,
                          border: Border.all(
                            color: selected
                                ? AppColors.neonRed
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(icon,
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'اسم المجلد',
                  hintStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: AppColors.textMuted),
                  prefixText: '$_selectedIcon  ',
                  prefixStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              NeonButton(
                label: 'إنشاء المجلد',
                onTap: () {
                  final name = _nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  ref.read(_foldersProvider.notifier).addFolder(
                        ChatFolder(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: name,
                          icon: _selectedIcon,
                          colorIndex: _selectedColor,
                        ),
                      );
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  final ChatFolder folder;
  final VoidCallback onDelete;

  const _FolderTile({required this.folder, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: 14,
        child: Row(
          children: [
            Text(folder.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  Text(
                    '${folder.chatIds.length} محادثة',
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.neonRed, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
