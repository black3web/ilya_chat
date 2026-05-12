// lib/features/stickers/sticker_keyboard.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/neon_widgets.dart';

// Free sticker API (Giphy / Tenor stickers)
const _giphyApiKey = 'GlVGYHkr3WSBnllca54iNt0yFbjz7L65';
const _giphyBaseUrl = 'https://api.giphy.com/v1/stickers';

class StickerKeyboard extends StatefulWidget {
  final void Function(String url, bool isAnimated) onStickerSelected;
  final double height;

  const StickerKeyboard({
    super.key,
    required this.onStickerSelected,
    this.height = 300,
  });

  @override
  State<StickerKeyboard> createState() => _StickerKeyboardState();
}

class _StickerKeyboardState extends State<StickerKeyboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  final _dio = Dio();

  List<Map<String, dynamic>> _trending = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _favorites = [];
  bool _loading = true;
  String _query = '';

  final _categories = ['trending', 'love', 'happy', 'sad', 'funny', 'wow'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _categories.length + 1, vsync: this);
    _loadFavorites();
    _fetchTrending();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = prefs.getStringList('favorite_stickers') ?? [];
    });
  }

  Future<void> _saveFavorite(String url) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_favorites.contains(url)) {
      _favorites.insert(0, url);
      if (_favorites.length > 30) _favorites = _favorites.take(30).toList();
    } else {
      _favorites.remove(url);
    }
    await prefs.setStringList('favorite_stickers', _favorites);
    setState(() {});
  }

  Future<void> _fetchTrending() async {
    setState(() => _loading = true);
    try {
      final res = await _dio.get('$_giphyBaseUrl/trending', queryParameters: {
        'api_key': _giphyApiKey,
        'limit': 30,
        'rating': 'g',
      });
      if (res.statusCode == 200) {
        final data = res.data['data'] as List;
        setState(() {
          _trending = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      // Fallback stickers from free source
      setState(() {
        _trending = _getFallbackStickers();
        _loading = false;
      });
    }
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      final res = await _dio.get('$_giphyBaseUrl/search', queryParameters: {
        'api_key': _giphyApiKey,
        'q': q,
        'limit': 24,
        'rating': 'g',
      });
      if (res.statusCode == 200) {
        final data = res.data['data'] as List;
        setState(() => _searchResults = data.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  Future<void> _fetchCategory(String cat) async {
    setState(() => _loading = true);
    try {
      final res = await _dio.get('$_giphyBaseUrl/search', queryParameters: {
        'api_key': _giphyApiKey,
        'q': cat,
        'limit': 24,
        'rating': 'g',
      });
      if (res.statusCode == 200) {
        final data = res.data['data'] as List;
        setState(() {
          _trending = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _getStickerUrl(Map<String, dynamic> sticker) {
    try {
      return sticker['images']['fixed_height']['url'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
            top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 6),
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.silverDim,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: GlassContainer(
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.silverDim, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) {
                        setState(() => _query = v);
                        _search(v);
                      },
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن ملصق...',
                        hintStyle: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Category tabs
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _CategoryChip(
                  label: '⭐',
                  selected: _tabCtrl.index == 0,
                  onTap: () {
                    _tabCtrl.animateTo(0);
                    setState(() {});
                  },
                ),
                ..._categories.asMap().entries.map((e) {
                  return _CategoryChip(
                    label: e.value,
                    selected: _tabCtrl.index == e.key + 1,
                    onTap: () {
                      _tabCtrl.animateTo(e.key + 1);
                      if (e.value == 'trending') {
                        _fetchTrending();
                      } else {
                        _fetchCategory(e.value);
                      }
                      setState(() {});
                    },
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Grid
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.neonRed, strokeWidth: 2),
                  )
                : _buildGrid(_query.isNotEmpty ? _searchResults : _trending),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> stickers) {
    if (stickers.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد ملصقات',
          style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppColors.textMuted),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: stickers.length,
      itemBuilder: (ctx, i) {
        final url = _getStickerUrl(stickers[i]);
        if (url.isEmpty) return const SizedBox();
        final isFav = _favorites.contains(url);

        return GestureDetector(
          onTap: () => widget.onStickerSelected(url, true),
          onLongPress: () => _saveFavorite(url),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => Container(
                    color: AppColors.surfaceLight,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.neonRed, strokeWidth: 1.5),
                    ),
                  ),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: AppColors.textMuted),
                ),
              ),
              if (isFav)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.neonRed.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded,
                        color: Colors.white, size: 10),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getFallbackStickers() {
    return [
      {'images': {'fixed_height': {'url': 'https://media.giphy.com/media/3oEjI6SIIHBdRxXI40/giphy.gif'}}},
      {'images': {'fixed_height': {'url': 'https://media.giphy.com/media/l0MYt5jPR6QX5pnqM/giphy.gif'}}},
      {'images': {'fixed_height': {'url': 'https://media.giphy.com/media/26u4lOMA8JKSnL9Uk/giphy.gif'}}},
      {'images': {'fixed_height': {'url': 'https://media.giphy.com/media/3oz8xAFtqoOUUrsh7W/giphy.gif'}}},
    ];
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: selected ? AppColors.neonRed : AppColors.textSecondary,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
