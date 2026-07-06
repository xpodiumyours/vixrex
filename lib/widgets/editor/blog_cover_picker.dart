import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

class BlogCoverPicker extends StatelessWidget {
  final Uint8List? coverBytes;
  final String? coverImageUrl;
  final bool isUploading;
  final VoidCallback onTap;

  const BlogCoverPicker({
    super.key,
    required this.coverBytes,
    required this.coverImageUrl,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCover = coverBytes != null || (coverImageUrl != null && coverImageUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kapak Fotoğrafı',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: AppColors.softText,
          ),
        ),
        const SizedBox(height: AppColors.spacing8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radius12),
          child: AspectRatio(
            aspectRatio: 16 / 7,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(AppColors.radius12),
                border: Border.all(color: AppColors.cardBorderDark),
              ),
              clipBehavior: Clip.antiAlias,
              child: isUploading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : hasCover
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            coverBytes != null
                                ? Image.memory(coverBytes!, fit: BoxFit.cover)
                                : Image.network(
                                    coverImageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                            Container(color: Colors.black38),
                            const Center(
                              child: Icon(
                                Icons.photo_library_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_rounded,
                              color: AppColors.mutedText,
                              size: 28,
                            ),
                            SizedBox(height: AppColors.spacing8),
                            Text(
                              'Fotoğraf Seç',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedText,
                                fontWeight: FontWeight.bold,
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
}
