import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/product_service.dart';
import 'package:vixrex/services/vitrin_cart_service.dart';
import 'package:vixrex/services/public_store_service.dart';
import 'package:vixrex/services/store_publish_service.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';
import 'package:vixrex/widgets/vitrin_cart_dock.dart';
import 'package:vixrex/widgets/vitrin_product_card.dart';

class PublicProductScreen extends StatefulWidget {
  const PublicProductScreen({
    super.key,
    required this.storeSlug,
    required this.productSlug,
    this.previewMode = false,
  });

  final String storeSlug;
  final String productSlug;
  final bool previewMode;

  @override
  State<PublicProductScreen> createState() => _PublicProductScreenState();
}

class _PublicProductScreenState extends State<PublicProductScreen> {
  late final Future<_PublicProductData?> _dataFuture = _load();
  final _pageController = PageController();
  int _imageIndex = 0;

  Future<_PublicProductData?> _load() async {
    final result = await const PublicStoreService().fetchPublishedStoreProducts(
      widget.storeSlug,
    );
    if (result.isFailure || result.data == null) return null;
    final row = result.data!;

    final storageVersion =
        (row['product_storage_version'] as num?)?.toInt() ?? 1;
    final storeId = (row['id'] ?? '').toString().trim();

    List<Product> products;
    if (storageVersion == 2 && storeId.isNotEmpty) {
      products = await ProductService().fetchVisibleProducts(storeId);
    } else {
      final raw = row['products'];
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! List) return null;
      products =
          decoded
              .whereType<Map>()
              .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
              .where((product) => product.isVisible)
              .toList();
    }

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
      products: products,
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
        title: FutureBuilder<_PublicProductData?>(
          future: _dataFuture,
          builder: (_, snapshot) {
            final name = snapshot.data?.product.name;
            return Text(name != null && name.isNotEmpty ? name : 'Ürün Detayı');
          },
        ),
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
      bottomNavigationBar: FutureBuilder<_PublicProductData?>(
        future: _dataFuture,
        builder: (_, snapshot) {
          final data = snapshot.data;
          if (data == null || widget.previewMode) {
            return const SizedBox.shrink();
          }
          return VitrinCartDock(
            storeSlug: widget.storeSlug,
            storeName: data.storeName,
            whatsappNumber: data.whatsapp,
          );
        },
      ),
      body: FutureBuilder<_PublicProductData?>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _ProductSkeleton();
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                        if (data.products.length > 1) ...[
                          const SizedBox(height: 28),
                          const Text(
                            'Vitrinin diğer ürünleri',
                            style: TextStyle(
                              color: AppColors.darkText,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildOtherProducts(data),
                        ],
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
                            (_, index) => CachedNetworkImage(
                              imageUrl: images[index],
                              fit: BoxFit.cover,
                              placeholder:
                                  (_, __) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
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
          const SizedBox(height: 12),
          _buildCartButton(data.product),
        ],
      ),
    );
  }

  int _cartQuantity(Product product) {
    final items =
        VitrinCartService.instance.items
            .where((i) => i.productSlug == widget.productSlug)
            .toList();
    return items.fold<int>(0, (sum, i) => sum + i.quantity);
  }

  Widget _buildCartButton(Product product) {
    final hasVariants = product.variants.isNotEmpty;
    final qty = _cartQuantity(product);
    if (_stockCap(product) <= 0) return const SizedBox.shrink();
    if (hasVariants) {
      return OutlinedButton(
        onPressed: () => _openVariantSheet(product),
        child: Text(
          qty > 0 ? 'Sepette ($qty) · Seçenekler →' : 'Seçenekleri gör →',
        ),
      );
    }
    if (qty == 0) {
      return ElevatedButton(
        onPressed: () {
          VitrinCartService.instance.add(
            VitrinCartItem(
              productSlug: widget.productSlug,
              productName: product.name,
              variantKey: 'standart',
              variantText: '',
              priceText: product.price,
              priceAmount: double.tryParse(
                product.price
                    .replaceAll(RegExp(r'[^0-9.,]'), '')
                    .replaceAll(',', '.'),
              ),
              imageUrl:
                  product.imagePath ??
                  (product.imageUrls.isNotEmpty ? product.imageUrls.first : ''),
              maxQuantity: product.stockQuantity,
              quantity: 1,
            ),
          );
          setState(() {});
        },
        child: const Text('+ Sepete ekle'),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            VitrinCartService.instance.setQuantity(
              widget.productSlug,
              'standart',
              qty - 1,
            );
            setState(() {});
          },
          icon: const Text('−'),
        ),
        Text('$qty'),
        IconButton(
          onPressed:
              qty >= _stockCap(product)
                  ? null
                  : () {
                    VitrinCartService.instance.setQuantity(
                      widget.productSlug,
                      'standart',
                      qty + 1,
                    );
                    setState(() {});
                  },
          icon: const Text('+'),
        ),
      ],
    );
  }

  int _stockCap(Product product) => product.stockQuantity ?? 10;

  double? _priceAmount(String price) {
    final clean = price
        .replaceAll(RegExp(r'[^0-9.,]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(clean);
  }

  Future<void> _openVariantSheet(Product product) async {
    final secilen = await showModalBottomSheet<ProductVariantData>(
      context: context,
      builder:
          (context) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children:
                  product.variants.map((variant) {
                    final etiket = variant.options.values
                        .where((value) => value.trim().isNotEmpty)
                        .join(' / ');
                    final stok = variant.stockQuantity ?? product.stockQuantity;
                    return ListTile(
                      title: Text(etiket.isEmpty ? 'Standart' : etiket),
                      subtitle: Text(
                        variant.priceAmount != null
                            ? '${variant.priceAmount!.toStringAsFixed(2)} TL'
                            : product.price,
                      ),
                      enabled: stok == null || stok > 0,
                      onTap: () => Navigator.of(context).pop(variant),
                    );
                  }).toList(),
            ),
          ),
    );
    if (secilen == null || !mounted) return;
    final etiket = secilen.options.values
        .where((value) => value.trim().isNotEmpty)
        .join(' / ');
    VitrinCartService.instance.add(
      VitrinCartItem(
        productSlug: widget.productSlug,
        productName: product.name,
        variantKey: secilen.id.isNotEmpty ? secilen.id : etiket,
        variantText: etiket,
        priceText:
            secilen.priceAmount != null
                ? '${secilen.priceAmount!.toStringAsFixed(2)} TL'
                : product.price,
        priceAmount: secilen.priceAmount ?? _priceAmount(product.price),
        imageUrl:
            secilen.imageUrls.isNotEmpty
                ? secilen.imageUrls.first
                : (product.primaryImageUrl ?? ''),
        maxQuantity: secilen.stockQuantity ?? product.stockQuantity,
        quantity: 1,
      ),
    );
    setState(() {});
  }

  Widget _buildOtherProducts(_PublicProductData data) {
    final digerleri = <Widget>[];
    for (var index = 0; index < data.products.length; index++) {
      final urun = data.products[index];
      if (urun.id == data.product.id) continue;
      final slug = _productSlug(urun, index);
      final qty = VitrinCartService.instance.items
          .where((item) => item.productSlug == slug)
          .fold<int>(0, (sum, item) => sum + item.quantity);
      digerleri.add(
        SizedBox(
          width: 220,
          height: VitrinProductCard.cardHeightForWidth(220),
          child: VitrinProductCard(
            name: urun.name,
            price: urun.price,
            category: urun.category,
            description: urun.description,
            imageUrls: urun.displayImageUrls,
            stockStatus: urun.stockStatus,
            hasVariants: urun.variants.isNotEmpty,
            cartQuantity: qty,
            maxQuantity: urun.stockQuantity,
            showCart: !widget.previewMode,
            onTap: () => context.push('/v/${widget.storeSlug}/urun/$slug'),
            onViewOptions:
                () => context.push('/v/${widget.storeSlug}/urun/$slug'),
            onAddToCart: () {
              VitrinCartService.instance.add(
                VitrinCartItem(
                  productSlug: slug,
                  productName: urun.name,
                  variantKey: 'standart',
                  variantText: '',
                  priceText: urun.price,
                  priceAmount: _priceAmount(urun.price),
                  imageUrl: urun.primaryImageUrl ?? '',
                  maxQuantity: urun.stockQuantity,
                  quantity: 1,
                ),
              );
              setState(() {});
            },
            onIncrement: () {
              VitrinCartService.instance.setQuantity(slug, 'standart', qty + 1);
              setState(() {});
            },
            onDecrement: () {
              VitrinCartService.instance.setQuantity(slug, 'standart', qty - 1);
              setState(() {});
            },
          ),
        ),
      );
    }
    if (digerleri.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 12, runSpacing: 12, children: digerleri);
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
    required this.products,
  });

  final String storeName;
  final String whatsapp;
  final String fallbackImage;
  final Product product;
  final List<Product> products;
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

class _ProductSkeleton extends StatelessWidget {
  const _ProductSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 24,
                width: 200,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: 280,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
