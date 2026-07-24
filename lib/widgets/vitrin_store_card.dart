import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/app_colors.dart';

class VitrinStoreCard extends StatelessWidget {
  final StoreData store;
  final bool isExample;
  final bool isFavorited;
  final bool isOwnStore;
  final VoidCallback? onTap;
  final VoidCallback onFavoritePressed;
  final VoidCallback onWhatsAppPressed;

  // Theme Colors from AppColors
  static const Color primaryColor = AppColors.primary;
  static const Color cardBorder = AppColors.border;
  static const Color darkText = AppColors.darkText;
  static const Color mutedText = AppColors.mutedText;

  const VitrinStoreCard({
    super.key,
    required this.store,
    required this.isExample,
    required this.isFavorited,
    required this.isOwnStore,
    this.onTap,
    required this.onFavoritePressed,
    required this.onWhatsAppPressed,
  });

  String get _whatsappButtonLabel {
    final cat = (store.kategori.isNotEmpty ? store.kategori : store.businessType).toLowerCase().trim();
    if (cat.contains('kuaför') ||
        cat.contains('güzellik') ||
        cat.contains('hizmet') ||
        cat.contains('servis') ||
        cat.contains('klinik') ||
        cat.contains('danışmanlık')) {
      return 'WhatsApp İletişim';
    }
    return 'WhatsApp Sipariş';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = store.shelfImageUrl.isNotEmpty;
    final status = store.status.trim();
    final isOpen = status.isEmpty || status.toLowerCase() == 'açık';
    final location =
        store.districtName.trim().isNotEmpty && store.provinceName.trim().isNotEmpty
            ? '${store.districtName.trim()}, ${store.provinceName.trim()}'
            : store.districtName.trim().isNotEmpty
            ? store.districtName.trim()
            : store.provinceName.trim().isNotEmpty
            ? store.provinceName.trim()
            : store.address.trim().isNotEmpty
            ? store.address.trim()
            : 'Konum belirtilmedi';

    final categoryLabel = (store.kategori.trim().isNotEmpty
            ? store.kategori.trim()
            : store.businessType.trim().isNotEmpty
            ? store.businessType.trim()
            : 'DİJİTAL VİTRİN')
        .toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOwnStore ? primaryColor.withValues(alpha: 0.8) : cardBorder,
          width: isOwnStore ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          if (isOwnStore)
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.20),
              blurRadius: 14,
              spreadRadius: 1,
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isExample ? null : onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Görsel Alanı ---
              Expanded(
                flex: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.network(
                        store.shelfImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                _buildImagePlaceholder(),
                      )
                    else
                      _buildImagePlaceholder(),

                    // İnce Karartma Gradyanı
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.transparent,
                              AppColors.surface.withValues(alpha: 0.90),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Durum Rozeti (Sol Üst)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _buildStatusBadge(isOpen),
                    ),

                    if (isExample)
                      Positioned(
                        top: 40,
                        left: 10,
                        child: _buildImageBadge('Örnek'),
                      ),

                    if (isOwnStore)
                      Positioned(
                        bottom: 8,
                        left: 10,
                        child: _buildImageBadge(
                          'Senin vitrinin',
                          highlighted: true,
                        ),
                      ),

                    // Favori Butonu (Sağ Üst)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isFavorited
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color:
                                isFavorited
                                    ? Colors.redAccent
                                    : Colors.white.withValues(alpha: 0.9),
                          ),
                          onPressed: onFavoritePressed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Detay ve İşlem Alanı ---
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Kategori Etiketi
                    Text(
                      categoryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Mağaza Adı
                    Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.darkText,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Konum Satırı
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Tam Genişlik SaaS WhatsApp Butonu
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: onWhatsAppPressed,
                        icon: const Icon(
                          Icons.chat_bubble_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        label: Text(
                          _whatsappButtonLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A884),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (isOpen ? AppColors.success : AppColors.error).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOpen ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'CANLI' : 'KAPALI',
            style: TextStyle(
              color: isOpen ? AppColors.success : AppColors.error,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBadge(String label, {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            highlighted
                ? AppColors.primary
                : AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              highlighted
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted ? AppColors.bgEditor : AppColors.darkText,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surfaceSoft, AppColors.bgEditor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.storefront_outlined,
              color: AppColors.primary,
              size: 34,
            ),
            const SizedBox(height: 6),
            Text(
              'Kapak görseli bekleniyor',
              style: TextStyle(
                color: AppColors.mutedText.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
