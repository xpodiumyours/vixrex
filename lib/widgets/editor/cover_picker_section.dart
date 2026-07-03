import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vitrinx/theme/app_colors.dart';

class CoverPickerSection extends StatelessWidget {
  final Uint8List? coverBytes;
  final String? coverUrl;
  final String? coverFileName;
  final VoidCallback onTap;
  final VoidCallback? onAutoFillTap;

  const CoverPickerSection({
    super.key,
    required this.coverBytes,
    required this.coverUrl,
    required this.coverFileName,
    required this.onTap,
    this.onAutoFillTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCover = coverBytes != null || (coverUrl?.trim().isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kapak Fotoğrafı',
          style: TextStyle(
            color: AppColors.softText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 7,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorderDark),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasCover ? _buildCoverPreview() : _EmptyCoverState(onAutoFillTap: onAutoFillTap),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (coverBytes != null)
          Image.memory(coverBytes!, fit: BoxFit.cover)
        else
          Image.network(
            coverUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _CoverPlaceholder(),
          ),
        Positioned(
          right: 10,
          bottom: 10,
          child: _CoverBadge(
            text: coverFileName == null ? 'Fotoğrafı değiştir' : coverFileName!,
          ),
        ),
      ],
    );
  }
}

class _EmptyCoverState extends StatelessWidget {
  final VoidCallback? onAutoFillTap;

  const _EmptyCoverState({this.onAutoFillTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_photo_alternate_rounded,
          color: AppColors.primary,
          size: 30,
        ),
        const SizedBox(height: 6),
        const Text(
          'Kapak fotoğrafı ekle',
          style: TextStyle(
            color: AppColors.darkText,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'İsteğe bağlı — sonra da eklenebilir',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (onAutoFillTap != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAutoFillTap,
            icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primary),
            label: const Text(
              'Hazır şablonlardan seç',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceSoft, AppColors.bgEditor],
        ),
      ),
      child: const Center(
        child: Icon(Icons.storefront_rounded, color: AppColors.primary, size: 38),
      ),
    );
  }
}

class _CoverBadge extends StatelessWidget {
  final String text;

  const _CoverBadge({required this.text});

  @override
  Widget build(BuildContext context) {
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
