import 'package:flutter/material.dart';
import 'package:vitrinx/models/landing_demo_profile.dart';
import 'package:vitrinx/theme/app_colors.dart';

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
                      Container(
                        height: 172,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(profile.coverImageUrl),
                            onError: (exception, stackTrace) {},
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
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
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
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
                                        size: 24,
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
                                const SizedBox(height: 8),
                                Text(
                                  profile.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.8,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        profile.category,
                                        style: TextStyle(
                                          color: profile.accentColor,
                                          fontSize: 13,
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
                                          fontSize: 12,
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
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: AppColors.surface,
                          padding: const EdgeInsets.all(16),
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
                              const SizedBox(height: 8),
                              Text(
                                profile.description,
                                style: const TextStyle(
                                  color: AppColors.darkTextAlt,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
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
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
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
                                const SizedBox(height: 16),
                                const Text(
                                  'Bağlantılar',
                                  style: TextStyle(
                                    color: AppColors.darkText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Column(
                                    children:
                                        profile.links.take(2).map((link) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: InkWell(
                                              onTap: onPreviewTap,
                                              borderRadius: BorderRadius.circular(14),
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: AppColors.bgLight,
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: AppColors.border,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 36,
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        color: link.color.withValues(
                                                          alpha: 0.14,
                                                        ),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Icon(
                                                        link.icon,
                                                        color: link.color,
                                                        size: 18,
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
                                        }).toList(),
                                  ),
                                ),
                              ],
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
