import 'package:flutter/material.dart';
import 'package:vitrinx/services/category_image_service.dart';
import 'package:vitrinx/theme/app_colors.dart';

/// Sadece kapak şablonu seçimi için bottom sheet
/// Kullanıcı bir görsele tıklar → hemen uygulanır
class CoverTemplatePickerSheet extends StatefulWidget {
  final String categoryKey;
  final String categoryLabel;
  final void Function(String coverUrl) onCoverSelected;

  const CoverTemplatePickerSheet({
    super.key,
    required this.categoryKey,
    required this.categoryLabel,
    required this.onCoverSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required String categoryKey,
    required String categoryLabel,
    required void Function(String coverUrl) onCoverSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CoverTemplatePickerSheet(
        categoryKey: categoryKey,
        categoryLabel: categoryLabel,
        onCoverSelected: onCoverSelected,
      ),
    );
  }

  @override
  State<CoverTemplatePickerSheet> createState() => _CoverTemplatePickerSheetState();
}

class _CoverTemplatePickerSheetState extends State<CoverTemplatePickerSheet> {
  bool _isLoading = false;
  List<CategoryTemplateImage> _covers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCovers();
  }

  Future<void> _loadCovers() async {
    setState(() => _isLoading = true);
    try {
      final set = await CategoryImageService.getImagesForCategory(widget.categoryKey);
      setState(() {
        _covers = set.coverImages;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Görsel yüklenemedi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.image_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.categoryLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kapak fotoğrafı seçin',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCovers,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_covers.isEmpty) {
      return const Center(
        child: Text('Bu kategori için kapak görseli bulunamadı.'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _covers.length,
      itemBuilder: (context, index) {
        final cover = _covers[index];
        return GestureDetector(
          onTap: () {
            widget.onCoverSelected(cover.imageUrl);
            Navigator.pop(context);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  cover.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
                // Hover overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Label
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    cover.title ?? 'Kapak ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
