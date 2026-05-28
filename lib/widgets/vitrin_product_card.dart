import 'package:flutter/material.dart';

class VitrinProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String category;
  final String description;
  final String? imagePath;
  final String stockStatus;
  final VoidCallback? onWhatsAppTap;

  const VitrinProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    this.imagePath,
    this.stockStatus = 'Mevcut',
    this.onWhatsAppTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0x08FFFFFF) : Colors.white,
        borderRadius:
            (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
            BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0x08000000),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.2,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top:
                    ((theme.cardTheme.shape as RoundedRectangleBorder?)
                                ?.borderRadius
                            as BorderRadius?)
                        ?.topLeft ??
                    const Radius.circular(16),
              ),
              child: Container(
                color: isDark ? const Color(0x0DFFFFFF) : Colors.grey.shade50,
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 40,
                    color: theme.primaryColor.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: theme.primaryColor.withOpacity(0.5),
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (stockStatus != 'Mevcut')
                      Text(
                        stockStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color:
                              stockStatus == 'Tükendi'
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Tooltip(
                  message: description,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                        decoration: const BoxDecoration(
                          color: Color(0x1A25D366),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat,
                          size: 14,
                          color: Color(0xFF25D366),
                        ),
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
