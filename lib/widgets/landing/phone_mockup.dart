import 'package:flutter/material.dart';
import 'package:vixrex/models/landing_demo_profile.dart';
import 'package:vixrex/theme/app_colors.dart';

class PhoneMockup extends StatelessWidget {
  final HeroDemoProfile profile;
  final VoidCallback? onPreviewTap;

  const PhoneMockup({
    super.key,
    required this.profile,
    this.onPreviewTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale =
            constraints.maxHeight < 700
                ? (constraints.maxHeight / 700).clamp(0.5, 1.0)
                : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 320,
            height: 640,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF26313B), AppColors.surface],
              ),
              borderRadius: BorderRadius.circular(44),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 60,
                  offset: const Offset(0, 30),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgEditor,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 156,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    profile.accentColor.withValues(alpha: 0.18),
                                    AppColors.bgLight,
                                  ],
                                ),
                              ),
                            ),
                            Image.network(
                              profile.coverImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    color: AppColors.bgLight,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      profile.icon,
                                      color: profile.accentColor.withValues(alpha: 0.9),
                                      size: 42,
                                    ),
                                  ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.16),
                                    Colors.black.withValues(alpha: 0.52),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: profile.accentColor.withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: profile.accentColor.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Icon(
                                          profile.icon,
                                          color: profile.accentColor,
                                          size: 22,
                                        ),
                                      ),
                                      const Spacer(),
                                      InkWell(
                                        onTap: onPreviewTap,
                                        borderRadius: BorderRadius.circular(999),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(999),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.16),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                profile.badgeIcon,
                                                color: profile.accentColor,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                profile.badgeText,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    profile.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.8,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          profile.category,
                                          style: TextStyle(
                                            color: profile.accentColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: profile.secondaryBadgeColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          profile.secondaryBadgeText,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: AppColors.surface,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hakkında',
                                style: TextStyle(
                                  color: AppColors.darkText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                profile.description,
                                style: const TextStyle(
                                  color: AppColors.darkTextAlt,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    profile.actions.map((action) {
                                      final title = action.title?.trim() ?? '';
                                      return InkWell(
                                        onTap: onPreviewTap,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: action.color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                action.icon,
                                                color: action.color,
                                                size: 16,
                                              ),
                                              if (title.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Text(
                                                  title,
                                                  style: TextStyle(
                                                    color: action.color,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                              if (profile.links.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                ...profile.links.take(2).map((link) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: InkWell(
                                      onTap: onPreviewTap,
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.bgLight,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: link.color.withValues(alpha: 0.14),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                link.icon,
                                                color: link.color,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    link.title,
                                                    style: const TextStyle(
                                                      color: AppColors.darkText,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    link.subtitle,
                                                    style: const TextStyle(
                                                      color: AppColors.mutedText,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 12,
                                              color: AppColors.mutedText,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                              if (profile.galleryImages.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Vitrin galerisi',
                                        style: TextStyle(
                                          color: AppColors.darkText,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: profile.accentColor.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${profile.galleryImages.length} fotoğraf',
                                        style: TextStyle(
                                          color: profile.accentColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 52,
                                  child: Row(
                                    children: List.generate(
                                      profile.galleryImages.take(3).length,
                                      (index) {
                                        final imageUrl =
                                            profile.galleryImages.take(3).elementAt(index);
                                        return Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              right: index == 2 ? 0 : 8,
                                            ),
                                            child: InkWell(
                                              onTap: onPreviewTap,
                                              borderRadius: BorderRadius.circular(12),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  color: AppColors.bgLight,
                                                  child: Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (context, error, stackTrace) =>
                                                            Container(
                                                              color: AppColors.bgLight,
                                                              alignment: Alignment.center,
                                                              child: Icon(
                                                                Icons.image_outlined,
                                                                color: profile.accentColor,
                                                                size: 20,
                                                              ),
                                                            ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              // Vitrin hazır alt bölümü
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.bgLight,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Vitrin hazır',
                                            style: TextStyle(
                                              color: AppColors.darkText,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${profile.links.length} bağlantı',
                                            style: const TextStyle(
                                              color: AppColors.mutedText,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: profile.accentColor.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.qr_code_2_rounded,
                                        color: profile.accentColor,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
