import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/config/public_site_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/vitrin_view_service.dart';
import 'package:vitrinx/widgets/vitrin_view.dart';

class PublicVitrinScreen extends StatefulWidget {
  final String slug;
  final StoreData? mockStoreData;

  const PublicVitrinScreen({super.key, required this.slug, this.mockStoreData});

  @override
  State<PublicVitrinScreen> createState() => _PublicVitrinScreenState();
}

class _PublicVitrinScreenState extends State<PublicVitrinScreen> {
  late final Future<StoreData?> _storeFuture;

  @override
  void initState() {
    super.initState();
    _storeFuture = _fetchStore();
  }

  Future<StoreData?> _fetchStore() async {
    if (widget.mockStoreData != null) {
      return widget.mockStoreData;
    }
    final response =
        await Supabase.instance.client
            .from('stores')
            .select(
              'slug,name,business_type,description,corporate_bio,whatsapp,instagram,website,address,latitude,longitude,location_accuracy_meters,location_consent_at,location_source,theme,status,marketplace_links,references_link,shelf_image_url,gallery_items,is_published,is_store,products',
            )
            .eq('slug', widget.slug)
            .eq('is_published', true)
            .maybeSingle();

    if (response == null) return null;
    unawaited(
      const VitrinViewService().recordView(
        slug: widget.slug,
        source: _readViewSource(),
      ),
    );
    return _storeDataFromSupabase(response);
  }

  StoreData _storeDataFromSupabase(Map<String, dynamic> data) {
    final description = _readString(data['description']);
    final corporateBio = _readString(
      data['corporate_bio'],
      fallback: description,
    );

    return StoreData(
      name: _readString(data['name']),
      businessType: _readString(data['business_type']),
      description: description,
      whatsapp: _readString(data['whatsapp']),
      instagram: _readString(data['instagram']),
      website: _readString(data['website']),
      address: _readString(data['address']),
      latitude: _readDouble(data['latitude']),
      longitude: _readDouble(data['longitude']),
      locationAccuracyMeters: _readDouble(data['location_accuracy_meters']),
      locationConsentAt: _readDateTime(data['location_consent_at']),
      locationSource: _readString(data['location_source']),
      theme: _readString(data['theme'], fallback: 'Premium'),
      status: _readString(data['status']),
      isEsnafMode: true,
      isStore: _readBool(data['is_store']),
      corporateBio: corporateBio,
      referencesLink: _readString(data['references_link']),
      shelfImageUrl: _readString(data['shelf_image_url']),
      galleryItems: _parseGalleryItems(data['gallery_items']),
      marketplaceLinks: _parseMarketplaceLinks(data['marketplace_links']),
      products: _parseProducts(data['products']),
    );
  }

  String _readString(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  DateTime? _readDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _readViewSource() {
    final source =
        Uri.base.queryParameters['src'] ?? Uri.base.queryParameters['source'];
    final normalized = source?.trim().toLowerCase();

    if (normalized == 'direct' || normalized == 'qr' || normalized == 'share') {
      return normalized!;
    }

    return source == null ? 'direct' : 'unknown';
  }

  List<MarketplaceLink> _parseMarketplaceLinks(Object? rawLinks) {
    try {
      final decodedLinks = rawLinks is String ? jsonDecode(rawLinks) : rawLinks;

      if (decodedLinks is! List) return [];

      return decodedLinks
          .whereType<Map>()
          .map(
            (link) => MarketplaceLink(
              id: UniqueKey().toString(),
              platform: _readString(link['platform']),
              url: _readString(link['url']),
            ),
          )
          .where(
            (link) =>
                link.platform.trim().isNotEmpty && link.url.trim().isNotEmpty,
          )
          .toList();
    } catch (error) {
      debugPrint('Marketplace links parse error: $error');
      return [];
    }
  }

  List<Product> _parseProducts(Object? rawProducts) {
    try {
      final decodedProducts =
          rawProducts is String ? jsonDecode(rawProducts) : rawProducts;
      if (decodedProducts is! List) return [];

      return decodedProducts
          .whereType<Map>()
          .map(
            (p) => Product(
              id: _readString(p['id']),
              name: _readString(p['name']),
              price: _readString(p['price']),
              description: _readString(p['description']),
              category: _readString(p['category'], fallback: 'Genel'),
              stockStatus: _readString(
                p['stockStatus'] ?? p['stock_status'],
                fallback: 'Mevcut',
              ),
              imagePath:
                  p['imagePath'] != null
                      ? _readString(p['imagePath'])
                      : (p['image_path'] != null
                          ? _readString(p['image_path'])
                          : null),
            ),
          )
          .toList();
    } catch (error) {
      debugPrint('Products parse error: $error');
      return [];
    }
  }

  List<StoreGalleryItem> _parseGalleryItems(Object? rawItems) {
    try {
      final decodedItems = rawItems is String ? jsonDecode(rawItems) : rawItems;

      if (decodedItems is! List) return [];

      return decodedItems
          .whereType<Map>()
          .map(
            (item) =>
                StoreGalleryItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.imageUrl.trim().isNotEmpty)
          .take(12)
          .toList();
    } catch (error) {
      debugPrint('Gallery items parse error: $error');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StoreData?>(
      future: _storeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PublicVitrinStateView(
            title: 'Vitrin yükleniyor...',
            icon: Icons.hourglass_empty_rounded,
            showLoader: true,
          );
        }

        if (snapshot.hasError) {
          debugPrint('Public vitrin load error: ${snapshot.error}');
          return const _PublicVitrinStateView(
            title: 'Vitrin yüklenirken bir sorun oluştu.',
            icon: Icons.info_outline_rounded,
          );
        }

        final storeData = snapshot.data;
        if (storeData == null) {
          return const _PublicVitrinStateView(
            title: 'Vitrin bulunamadı.',
            icon: Icons.search_off_rounded,
          );
        }

        final publicLink = PublicSiteConfig.buildPublicLink(
          '/v/${Uri.encodeComponent(widget.slug)}',
        );

        return _PublicVitrinShell(
          child: VitrinView(
            storeData: storeData,
            publicMode: true,
            publicLink: publicLink,
          ),
        );
      },
    );
  }
}

class _PublicVitrinShell extends StatelessWidget {
  final Widget child;

  const _PublicVitrinShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF4F8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 640;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 0,
                vertical: isDesktop ? 24 : 0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isDesktop ? 28 : 0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow:
                            isDesktop
                                ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 30,
                                    offset: const Offset(0, 16),
                                  ),
                                ]
                                : null,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PublicVitrinStateView extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool showLoader;

  const _PublicVitrinStateView({
    required this.title,
    required this.icon,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Icon(icon, color: const Color(0xFFFF5A1F), size: 26),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                if (showLoader) ...[
                  const SizedBox(height: 18),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF5A1F),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
