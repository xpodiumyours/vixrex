import 'package:flutter/material.dart';

class VitrinProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String category;
  final String description;
  final String? imagePath;

  const VitrinProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    this.imagePath,
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
          // Product Image Area
          AspectRatio(
            aspectRatio: 1,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.w900, 
                    color: theme.primaryColor.withValues(alpha: 0.5),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12, 
                    color: isDark ? Colors.white54 : Colors.black54, 
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.w900, 
                        color: theme.primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat, size: 16, color: Color(0xFF25D366)),
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
