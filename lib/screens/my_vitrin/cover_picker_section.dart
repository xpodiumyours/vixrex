import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vitrinx/theme/app_colors.dart';

class CoverPickerSection extends StatelessWidget {
  final Uint8List? coverBytes;
  final String? coverUrl;
  final String? coverFileName;
  final VoidCallback onPickCoverPhoto;

  const CoverPickerSection({
    super.key,
    required this.coverBytes,
    required this.coverUrl,
    required this.coverFileName,
    required this.onPickCoverPhoto,
  });

  static const Color _primaryColor = AppColors.primary;
  static const Color _darkText = AppColors.darkText;
  static const Color _mutedText = AppColors.mutedText;
  static const Color _softText = AppColors.softText;
  static const Color _inputBg = AppColors.inputBg;
  static const Color _cardBorder = AppColors.border;

  bool get _hasCover => coverBytes != null || (coverUrl?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kapak Fotoğrafı',
          style: TextStyle(
            color: _softText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onPickCoverPhoto,
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 7,
            child: Container(
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  _hasCover
                      ? Stack(
                        fit: StackFit.expand,
                        children: [
                          if (coverBytes != null)
                            Image.memory(coverBytes!, fit: BoxFit.cover)
                          else
                            Image.network(
                              coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _coverPlaceholder(),
                            ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: _badge(
                              coverFileName == null
                                  ? 'Fotoğrafı değiştir'
                                  : coverFileName!,
                            ),
                          ),
                        ],
                      )
                      : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            color: _primaryColor,
                            size: 30,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Kapak fotoğrafı ekle',
                            style: TextStyle(
                              color: _darkText,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'İsteğe bağlı — sonra da eklenebilir',
                            style: TextStyle(
                              color: _mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceSoft, AppColors.bgEditor],
        ),
      ),
      child: const Center(
        child: Icon(Icons.storefront_rounded, color: _primaryColor, size: 38),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
