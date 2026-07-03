import 'package:flutter/material.dart';
import 'package:vitrinx/services/category_image_service.dart';
import 'package:vitrinx/widgets/auto_fill/category_auto_fill_sheet.dart';
import 'package:vitrinx/theme/app_colors.dart';

/// Vitrin formunda kategori secildiginde gosterilen
/// "Hazir gorseller kullan" banner'i
class AutoFillBanner extends StatefulWidget {
  final String kategori;
  final String storeId;
  final VoidCallback? onApplied;
  final VoidCallback? onTap;

  const AutoFillBanner({
    super.key,
    required this.kategori,
    required this.storeId,
    this.onApplied,
    this.onTap,
  });

  @override
  State<AutoFillBanner> createState() => _AutoFillBannerState();
}

class _AutoFillBannerState extends State<AutoFillBanner> {
  bool _hasTemplate = false;
  int _templateCount = 0;
  String? _categoryKey;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTemplate();
  }

  @override
  void didUpdateWidget(covariant AutoFillBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kategori != widget.kategori) {
      _checkTemplate();
    }
  }

  Future<void> _checkTemplate() async {
    if (widget.kategori.trim().isEmpty) {
      setState(() {
        _hasTemplate = false;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    final key = mapKategoriToKey(widget.kategori);
    if (key == null) {
      setState(() {
        _hasTemplate = false;
        _isLoading = false;
      });
      return;
    }

    try {
      final count = await CategoryImageService.getTemplateCount(widget.kategori);
      setState(() {
        _categoryKey = key;
        _hasTemplate = count > 0;
        _templateCount = count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasTemplate = false;
        _isLoading = false;
      });
    }
  }

  void _openSheet() {
    if (_categoryKey == null) return;

    CategoryAutoFillSheet.show(
      context: context,
      categoryKey: _categoryKey!,
      categoryLabel: widget.kategori,
      storeId: widget.storeId,
      onApplied: widget.onApplied,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_hasTemplate || _categoryKey == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.landingBlueAccent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_fix_high_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hazir gorseller mevcut!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.kategori} kategorisi icin $_templateCount adet hazir gorsel seni bekliyor.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onTap ?? _openSheet,
              icon: const Icon(Icons.photo_library_rounded, size: 18),
              label: const Text(
                'Hazir Gorselleri Kullan',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
