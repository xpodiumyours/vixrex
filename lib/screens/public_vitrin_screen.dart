import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/public_store_service.dart';
import 'package:vixrex/services/product_service.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/vitrin_view_service.dart';
import 'package:vixrex/widgets/vitrin_view.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/config/app_router.dart';

class PublicVitrinScreen extends StatefulWidget {
  final String slug;
  final StoreData? mockStoreData;
  final bool bypassTracker;

  const PublicVitrinScreen({
    super.key,
    required this.slug,
    this.mockStoreData,
    this.bypassTracker = false,
  });

  @override
  State<PublicVitrinScreen> createState() => _PublicVitrinScreenState();

  /// Supabase public store satırını [StoreData]'ya çevirir (logo + Google dahil).
  static StoreData mapStoreFromSupabase({
    required String slug,
    required Map<String, dynamic> data,
  }) {
    final description = _readString(data['description']);
    final corporateBio = _readString(
      data['corporate_bio'],
      fallback: description,
    );

    final rawBooking = data['booking_settings'];
    dynamic bookingMap;
    if (rawBooking is List && rawBooking.isNotEmpty) {
      bookingMap = rawBooking.first;
    } else if (rawBooking is Map) {
      bookingMap = rawBooking;
    }

    final bookingSettings =
        bookingMap != null
            ? BookingSettings.fromJson(Map<String, dynamic>.from(bookingMap))
            : null;

    final storeId = _readString(data['id']);

    return StoreData(
      id: storeId.isEmpty ? null : storeId,
      slug: slug,
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
      logoUrl:
          _readString(data['logo_url']).isEmpty
              ? null
              : _readString(data['logo_url']),
      googleBusinessLink: _readString(data['google_business_link']),
      galleryItems: _parseGalleryItems(data['gallery_items']),
      marketplaceLinks: _parseMarketplaceLinks(data['marketplace_links']),
      // Ürünler ilişkisel products tablosundan yüklenir
      products: [],
      offerings: _parseOfferings(data['offerings']),
      kategori: _readString(data['kategori']),
      workingHours: _readString(data['working_hours']),
      bookingSettings: bookingSettings,
    );
  }

  static List<StoreOffering> _parseOfferings(Object? rawOfferings) {
    try {
      final decodedOfferings =
          rawOfferings is String ? jsonDecode(rawOfferings) : rawOfferings;
      if (decodedOfferings is! List) return [];

      return decodedOfferings
          .whereType<Map>()
          .map((o) => StoreOffering.fromJson(Map<String, dynamic>.from(o)))
          .where((o) => o.title.trim().isNotEmpty)
          .take(6)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static List<MarketplaceLink> _parseMarketplaceLinks(Object? rawLinks) {
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
              subtitle: _readString(link['subtitle'] ?? ''),
            ),
          )
          .where(
            (link) =>
                link.platform.trim().isNotEmpty && link.url.trim().isNotEmpty,
          )
          .toList();
    } catch (_) {
      return [];
    }
  }



  static List<StoreGalleryItem> _parseGalleryItems(Object? rawItems) {
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
    } catch (_) {
      return [];
    }
  }
}

class _PublicVitrinScreenState extends State<PublicVitrinScreen> {
  late final Future<StoreData?> _storeFuture;
  late final Future<bool> _isOwnerFuture;

  @override
  void initState() {
    super.initState();
    _storeFuture = _fetchStore();
    _isOwnerFuture = _isOwnedByThisDevice();
  }

  String? _getFragmentToken() {
    try {
      final fragment = Uri.base.fragment;
      if (fragment.contains('randevu_token=')) {
        final reg = RegExp(r'randevu_token=([^&]+)');
        final match = reg.firstMatch(fragment);
        if (match != null) {
          return match.group(1);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Slug parse error: $e');
    }
    return null;
  }

  Future<StoreData?> _fetchStore() async {
    if (widget.mockStoreData != null) {
      return widget.mockStoreData;
    }

    final result = await const PublicStoreService().fetchPublishedStoreBySlug(
      widget.slug,
    );
    if (result.isFailure || result.data == null) return null;
    final response = result.data!;

    unawaited(
      const VitrinViewService().recordView(
        slug: widget.slug,
        source: _readViewSource(),
      ),
    );

    final store = PublicVitrinScreen.mapStoreFromSupabase(
      slug: widget.slug,
      data: response,
    );
    final storeId = (response['id'] ?? '').toString().trim();
    if (storeId.isNotEmpty) {
      store.products = await ProductService().fetchVisibleProducts(storeId);
    }
    return store;
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

  Future<bool> _isOwnedByThisDevice() async {
    final info =
        await const StoreLocalStorageService().loadPublishedVitrinInfo();
    if (info == null) return false;
    return info.slug.trim() == widget.slug.trim() &&
        info.editToken.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    // Eski #randevu_token= → canonical /v/{slug}/randevu/{token}
    if (!widget.bypassTracker) {
      final token = _getFragmentToken();
      if (token != null && token.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          final path = PublicSiteConfig.buildBookingTrackerPath(
            widget.slug,
            token,
          );
          context.go(path);
        });
        return const _PublicVitrinStateView(
          title: 'Randevu takip açılıyor...',
          icon: Icons.hourglass_empty_rounded,
          showLoader: true,
        );
      }
    }
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

        return FutureBuilder<bool>(
          future: _isOwnerFuture,
          builder: (context, ownerSnapshot) {
            return _PublicVitrinShell(
              showOwnerBar: ownerSnapshot.data == true,
              onEdit: () {
                AppRouter.navigateToMyVitrin(context);
              },
              child: VitrinView(
                storeData: storeData,
                publicMode: true,
                publicLink: publicLink,
              ),
            );
          },
        );
      },
    );
  }
}

class _PublicVitrinShell extends StatelessWidget {
  final Widget child;
  final bool showOwnerBar;
  final VoidCallback? onEdit;

  const _PublicVitrinShell({
    required this.child,
    this.showOwnerBar = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071322),
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
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1180 : 500),
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
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: showOwnerBar ? 72 : 0,
                            ),
                            child: child,
                          ),
                          if (showOwnerBar)
                            Positioned(
                              top: 12,
                              left: 12,
                              right: 12,
                              child: _PublicOwnerBar(onEdit: onEdit),
                            ),
                        ],
                      ),
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

class _PublicOwnerBar extends StatelessWidget {
  final VoidCallback? onEdit;

  const _PublicOwnerBar({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1F0F172A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFEAFBF1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF059669),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vitrinin yayında',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Yalnızca sen bu alanı görürsün',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 15),
            label: const Text('Düzenle'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF111827),
              backgroundColor: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
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
                  child: Icon(icon, color: AppColors.brandOrange, size: 26),
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
                      color: AppColors.brandOrange,
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
