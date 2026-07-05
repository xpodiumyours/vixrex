import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

class CoverPickerSection extends StatelessWidget {
  final Uint8List? coverBytes;
  final String? coverUrl;
  final String? coverFileName;
  final VoidCallback onTap;
  final VoidCallback onCameraTap;
  final VoidCallback? onAutoFillTap;

  const CoverPickerSection({
    super.key,
    required this.coverBytes,
    required this.coverUrl,
    required this.coverFileName,
    required this.onTap,
    required this.onCameraTap,
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
        AspectRatio(
          aspectRatio: 16 / 7,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorderDark),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasCover ? _buildCoverPreview() : const _CoverPlaceholder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                onPressed: onTap,
                icon: Icons.add_photo_alternate_rounded,
                label: 'Fotoğraf Yükle',
                isPrimary: false,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildActionButton(
                onPressed: onCameraTap,
                icon: Icons.photo_camera_rounded,
                label: 'Fotoğraf Çek',
                isPrimary: false,
              ),
            ),
            if (onAutoFillTap != null) ...[
              const SizedBox(width: 6),
              Expanded(
                child: _buildActionButton(
                  onPressed: onAutoFillTap!,
                  icon: Icons.auto_awesome_rounded,
                  label: 'Hazır Şablonlar',
                  isPrimary: true,
                ),
              ),
            ],
          ],
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

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.black),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkText,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
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
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_rounded, color: AppColors.primary, size: 32),
          SizedBox(height: 6),
          Text(
            'Kapak Fotoğrafı Ekle',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'İsteğe bağlı — sonra da eklenebilir',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
        color: Colors.black.withOpacity(0.66),
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
