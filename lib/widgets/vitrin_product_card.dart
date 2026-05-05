import 'package:flutter/material.dart';

class VitrinProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String category;
  final String description;
  final String? imagePath;
  final VoidCallback? onWhatsAppTap;

  const VitrinProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    this.imagePath,
    this.onWhatsAppTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.2,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: ((theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius as BorderRadius?)?.topLeft ?? const Radius.circular(16),
              ),
              child: Container(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                child: Center(
                  child: Icon(Icons.image_outlined, size: 40, color: theme.primaryColor.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9, 
                    fontWeight: FontWeight.w900, 
                    color: theme.primaryColor.withValues(alpha: 0.5),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.w900, 
                        color: theme.primaryColor,
                      ),
                    ),
                    InkWell(
                      onTap: onWhatsAppTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat, size: 14, color: Color(0xFF25D366)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
