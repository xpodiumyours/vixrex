import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitrinx/config/public_site_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/store_publish_service.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';

class PublicProductScreen extends StatefulWidget {
  const PublicProductScreen({
    super.key,
    required this.storeSlug,
    required this.productSlug,
  });

  final String storeSlug;
  final String productSlug;

  @override
  State<PublicProductScreen> createState() => _PublicProductScreenState();
}

class _PublicProductScreenState extends State<PublicProductScreen> {
  late final Future<_PublicProductData?> _dataFuture = _load();
  final _pageController = PageController();
  int _imageIndex = 0;

  Future<_PublicProductData?> _load() async {
    final row =
        await Supabase.instance.client
            .from('stores')
            .select(
              'slug,name,whatsapp,shelf_image_url,logo_url,products,is_published',
            )
            .eq('slug', widget.storeSlug)
            .eq('is_published', true)
            .maybeSingle();
    if (row == null) return null;

    final raw = row['products'];
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! List) return null;
    final products =
        decoded
            .whereType<Map>()
            .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
            .where((product) => product.isVisible)
            .toList();
    final requested = const StorePublishPayloadBuilder().generateSlug(
      widget.productSlug,
    );
    Product? found;
    for (var index = 0; index < products.length; index++) {
      final product = products[index];
      final slug = _productSlug(product, index);
      if (slug == requested) {
        found = product;
        break;
      }
    }
    if (found == null) return null;
    return _PublicProductData(
      storeName: (row['name'] ?? '').toString(),
      whatsapp: (row['whatsapp'] ?? '').toString(),
      fallbackImage:
          (row['shelf_image_url'] ?? row['logo_url'] ?? '').toString(),
      product: found,
    );
  }

  String _productSlug(Product product, int index) {
    final builder = const StorePublishPayloadBuilder();
    final explicit = product.slug?.trim() ?? '';
    if (explicit.isNotEmpty) return builder.generateSlug(explicit);
    final name = builder.generateSlug(product.name);
    final id = builder.generateSlug(product.id);
    return id == 'magazaniz' ? '$name-${index + 1}' : '$name-$id';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _share(Product product) async {
    final url = PublicSiteConfig.buildPublicLink(
      '/v/${widget.storeSlug}/urun/${widget.productSlug}',
    );
    await SharePlus.instance.share(
      ShareParams(text: '${product.name}\n$url', title: product.name),
    );
  }

  Future<void> _askOnWhatsApp(_PublicProductData data) async {
    final url = WhatsAppLinkHelper.buildInquiryUrl(
      number: data.whatsapp,
      storeName: data.storeName,
      itemTitle: data.product.name,
    );
    if (url != null) await launchUrl(Uri.parse(url));
  }

  void _backToStore() {
    try {
      context.go('/v/${widget.storeSlug}');
    } catch (_) {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        actions: [
          FutureBuilder<_PublicProductData?>(
            future: _dataFuture,
            builder:
                (_, snapshot) => IconButton(
                  tooltip: 'Ürünü paylaş',
                  onPressed:
                      snapshot.data == null
                          ? null
                          : () => _share(snapshot.data!.product),
                  icon: const Icon(Icons.share_outlined),
                ),
          ),
        ],
      ),
      body: FutureBuilder<_PublicProductData?>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _ProductNotFound(storeSlug: widget.storeSlug);
          }
          final data = snapshot.data!;
          final product = data.product;
          final images = List<String>.of(product.displayImageUrls);
          if (images.isEmpty && data.fallbackImage.trim().isNotEmpty) {
            images.add(data.fallbackImage.trim());
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 820;
              final imageGallery = _buildGallery(images);
              final details = _buildDetails(data);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child:
                        wide
                            ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: imageGallery),
                                const SizedBox(width: 24),
                                SizedBox(width: 380, child: details),
                              ],
                            )
                            : Column(
                              children: [
                                imageGallery,
                                const SizedBox(height: 20),
                                details,
                              ],
                            ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGallery(List<String> images) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              color: AppColors.surfaceSoft,
              child:
                  images.isEmpty
                      ? const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 54,
                          color: AppColors.mutedText,
                        ),
                      )
                      : PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged:
                            (index) => setState(() => _imageIndex = index),
                        itemBuilder:
                            (_, index) => Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                            ),
                      ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: index == _imageIndex ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color:
                      index == _imageIndex
                          ? AppColors.primary
                          : AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetails(_PublicProductData data) {
    final product = data.product;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton.icon(
            onPressed: _backToStore,
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text('${data.storeName} vitrinine dön'),
          ),
          const SizedBox(height: 8),
          Text(
            product.category,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            product.description.trim().isEmpty
                ? 'Ürün detayları için işletmeyle iletişime geçebilirsiniz.'
                : product.description,
            style: const TextStyle(color: AppColors.mutedText, height: 1.55),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _infoCard('Fiyat', product.price, false)),
              const SizedBox(width: 10),
              Expanded(child: _infoCard('Stok', product.stockStatus, true)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _askOnWhatsApp(data),
            icon: const Icon(Icons.chat_bubble_rounded),
            label: const Text("WhatsApp'tan Ürünü Sor"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, bool stock) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
          ),
          const SizedBox(height: 5),
          Text(
            value.trim().isEmpty
                ? (stock ? 'Bilgi alın' : 'Fiyat sorun')
                : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicProductData {
  const _PublicProductData({
    required this.storeName,
    required this.whatsapp,
    required this.fallbackImage,
    required this.product,
  });

  final String storeName;
  final String whatsapp;
  final String fallbackImage;
  final Product product;
}

class _ProductNotFound extends StatelessWidget {
  const _ProductNotFound({required this.storeSlug});

  final String storeSlug;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Ürün bulunamadı',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ürün kaldırılmış veya vitrinde gizlenmiş olabilir.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                try {
                  context.go('/v/$storeSlug');
                } catch (_) {
                  Navigator.maybePop(context);
                }
              },
              child: const Text('Vitrine geri dön'),
            ),
          ],
        ),
      ),
    );
  }
}
