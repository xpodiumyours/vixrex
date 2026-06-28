class Product {
  String id;
  String name;
  String price;
  String description;
  String? imagePath;
  String category;
  String stockStatus; // 'Mevcut', 'Tükendi', 'Son birkaç adet'
  String? slug;
  String? source;
  String? sourceMediaId;
  String? sourcePermalink;
  String? importedAt;

  Product({
    required this.id,
    this.name = '',
    this.price = '',
    this.description = '',
    this.imagePath,
    this.category = 'Tümü',
    this.stockStatus = 'Mevcut',
    this.slug,
    this.source,
    this.sourceMediaId,
    this.sourcePermalink,
    this.importedAt,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'imagePath': imagePath,
      'category': category,
      'stockStatus': stockStatus,
    };

    void putOptional(String key, String? value) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        json[key] = trimmed;
      }
    }

    putOptional('slug', slug);
    putOptional('source', source);
    putOptional('sourceMediaId', sourceMediaId);
    putOptional('sourcePermalink', sourcePermalink);
    putOptional('importedAt', importedAt);

    return json;
  }

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    price: (json['price'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    imagePath: json['imagePath'] as String?,
    category: (json['category'] ?? 'Tümü').toString(),
    stockStatus: (json['stockStatus'] ?? 'Mevcut').toString(),
    slug:
        (json['slug'] ?? '').toString().trim().isEmpty
            ? null
            : json['slug'].toString(),
    source:
        (json['source'] ?? '').toString().trim().isEmpty
            ? null
            : json['source'].toString(),
    sourceMediaId:
        (json['sourceMediaId'] ?? json['source_media_id'] ?? '')
                .toString()
                .trim()
                .isEmpty
            ? null
            : (json['sourceMediaId'] ?? json['source_media_id']).toString(),
    sourcePermalink:
        (json['sourcePermalink'] ?? json['source_permalink'] ?? '')
                .toString()
                .trim()
                .isEmpty
            ? null
            : (json['sourcePermalink'] ?? json['source_permalink']).toString(),
    importedAt:
        (json['importedAt'] ?? json['imported_at'] ?? '')
                .toString()
                .trim()
                .isEmpty
            ? null
            : (json['importedAt'] ?? json['imported_at']).toString(),
  );

  /// Mevcut ürünün bir kopyasını, belirtilen alanlar güncellenmiş şekilde döner.
  Product copyWith({
    String? id,
    String? name,
    String? price,
    String? description,
    String? imagePath,
    String? category,
    String? stockStatus,
    String? slug,
    String? source,
    String? sourceMediaId,
    String? sourcePermalink,
    String? importedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      stockStatus: stockStatus ?? this.stockStatus,
      slug: slug ?? this.slug,
      source: source ?? this.source,
      sourceMediaId: sourceMediaId ?? this.sourceMediaId,
      sourcePermalink: sourcePermalink ?? this.sourcePermalink,
      importedAt: importedAt ?? this.importedAt,
    );
  }
}

class MarketplaceLink {
  String id;
  // 'Trendyol', 'Hepsiburada', 'N11', 'Diğer', ya da özel başlık
  String platform;
  String url;

  /// Bağlantı kartının altında gösterilen kısa açıklama (isteğe bağlı).
  String subtitle;

  MarketplaceLink({
    required this.id,
    this.platform = 'Trendyol',
    this.url = '',
    this.subtitle = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'platform': platform,
    'url': url,
    'subtitle': subtitle,
  };

  factory MarketplaceLink.fromJson(Map<String, dynamic> json) =>
      MarketplaceLink(
        id: json['id'] ?? '',
        platform: json['platform'] ?? 'Trendyol',
        url: json['url'] ?? '',
        subtitle: (json['subtitle'] ?? '').toString(),
      );
}

class StoreOffering {
  String id;
  String title;
  String description;
  String price;
  int durationMinutes; // Dakika cinsinden (varsayılan 30, 15-240 arası)
  bool isBookable; // Randevuya açık mı?

  StoreOffering({
    required this.id,
    this.title = '',
    this.description = '',
    this.price = '',
    this.durationMinutes = 30,
    this.isBookable = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'durationMinutes': durationMinutes,
    'isBookable': isBookable,
  };

  factory StoreOffering.fromJson(Map<String, dynamic> json) => StoreOffering(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    price: (json['price'] ?? '').toString(),
    durationMinutes:
        (json['durationMinutes'] ?? json['duration_minutes'] ?? 30) as int,
    isBookable: (json['isBookable'] ?? json['is_bookable'] ?? false) as bool,
  );

  StoreOffering copyWith({
    String? id,
    String? title,
    String? description,
    String? price,
    int? durationMinutes,
    bool? isBookable,
  }) {
    return StoreOffering(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isBookable: isBookable ?? this.isBookable,
    );
  }
}

class StoreGalleryItem {
  String id;
  String imageUrl;
  String title;
  String description;

  StoreGalleryItem({
    required this.id,
    this.imageUrl = '',
    this.title = '',
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'imageUrl': imageUrl,
    'title': title,
    'description': description,
  };

  factory StoreGalleryItem.fromJson(Map<String, dynamic> json) {
    return StoreGalleryItem(
      id: (json['id'] ?? '').toString(),
      imageUrl:
          (json['imageUrl'] ?? json['image_url'] ?? json['url'] ?? '')
              .toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}

class StoreData {
  String name;
  String businessType;
  String description;
  String whatsapp;
  String instagram;
  String website;
  String address;
  String theme;
  String status;
  String slug;

  /// Esnaf modu flag'i. [PreviewScreen] tarafından kullanıldığı için kaldırılamaz.
  bool isEsnafMode;
  String? logoUrl;
  List<Product> products;
  List<MarketplaceLink> marketplaceLinks;

  // Kurumsal Mod Özel Alanları
  String corporateBio;

  /// Referans / müşteri yorum sayfası linki.
  /// Dolu ise public vitrinde Referanslarımız kartı görünür.
  String referencesLink;
  String shelfImageUrl;
  List<StoreGalleryItem> galleryItems;
  List<StoreOffering> offerings;
  bool isStore;
  String kategori;
  String workingHours;

  // Google ve Yerel SEO Alanları
  String provinceCode;
  String provinceName;
  String districtCode;
  String districtName;
  String googleBusinessLink;

  // Konum ve KVKK Alanları
  double? latitude;
  double? longitude;
  double? locationAccuracyMeters;
  DateTime? locationConsentAt;
  String? locationSource;
  BookingSettings? bookingSettings;

  // Yasal belge ve kamuya yayınlama beyanları
  bool privacyNoticeAcknowledged;
  DateTime? privacyNoticeAcknowledgedAt;
  String privacyNoticeVersion;
  String privacyNoticeHash;
  bool termsAccepted;
  DateTime? termsAcceptedAt;
  String termsVersion;
  String termsHash;
  bool publicationConsentAccepted;
  DateTime? publicationConsentAcceptedAt;
  DateTime? publicationConsentWithdrawnAt;
  String publicationConsentVersion;
  String publicationConsentHash;

  StoreData({
    this.name = '',
    this.businessType = 'Butik',
    this.description = '',
    this.whatsapp = '',
    this.instagram = '',
    this.website = '',
    this.address = '',
    this.theme = 'Premium',
    this.status = 'Açık',
    this.slug = '',
    this.isEsnafMode = true,
    this.logoUrl,
    List<Product>? products,
    List<MarketplaceLink>? marketplaceLinks,
    this.corporateBio = '',
    this.referencesLink = '',
    this.shelfImageUrl = '',
    List<StoreGalleryItem>? galleryItems,
    List<StoreOffering>? offerings,
    this.isStore = false,
    this.kategori = '',
    this.workingHours = '',
    this.provinceCode = '',
    this.provinceName = '',
    this.districtCode = '',
    this.districtName = '',
    this.googleBusinessLink = '',
    this.latitude,
    this.longitude,
    this.locationAccuracyMeters,
    this.locationConsentAt,
    this.locationSource,
    this.bookingSettings,
    this.privacyNoticeAcknowledged = false,
    this.privacyNoticeAcknowledgedAt,
    this.privacyNoticeVersion = '',
    this.privacyNoticeHash = '',
    this.termsAccepted = false,
    this.termsAcceptedAt,
    this.termsVersion = '',
    this.termsHash = '',
    this.publicationConsentAccepted = false,
    this.publicationConsentAcceptedAt,
    this.publicationConsentWithdrawnAt,
    this.publicationConsentVersion = '',
    this.publicationConsentHash = '',
  }) : products = products ?? [],
       marketplaceLinks = marketplaceLinks ?? [MarketplaceLink(id: '1')],
       galleryItems = galleryItems ?? [],
       offerings = offerings ?? [];

  Map<String, dynamic> toJson() => {
    'name': name,
    'businessType': businessType,
    'description': description,
    'whatsapp': whatsapp,
    'instagram': instagram,
    'website': website,
    'address': address,
    'theme': theme,
    'status': status,
    'slug': slug,
    'isEsnafMode': isEsnafMode,
    'logoUrl': logoUrl,
    'products': products.map((e) => e.toJson()).toList(),
    'marketplaceLinks': marketplaceLinks.map((e) => e.toJson()).toList(),
    'corporateBio': corporateBio,
    'referencesLink': referencesLink,
    'shelfImageUrl': shelfImageUrl,
    'galleryItems': galleryItems.map((e) => e.toJson()).toList(),
    'offerings': offerings.map((e) => e.toJson()).toList(),
    'isStore': isStore,
    'kategori': kategori,
    'workingHours': workingHours,
    'province_code': provinceCode,
    'province_name': provinceName,
    'district_code': districtCode,
    'district_name': districtName,
    'google_business_link': googleBusinessLink,
    'latitude': latitude,
    'longitude': longitude,
    'locationAccuracyMeters': locationAccuracyMeters,
    'locationConsentAt': locationConsentAt?.toIso8601String(),
    'locationSource': locationSource,
    'bookingSettings': bookingSettings?.toJson(),
    'privacyNoticeAcknowledged': privacyNoticeAcknowledged,
    'privacyNoticeAcknowledgedAt':
        privacyNoticeAcknowledgedAt?.toIso8601String(),
    'privacyNoticeVersion': privacyNoticeVersion,
    'privacyNoticeHash': privacyNoticeHash,
    'termsAccepted': termsAccepted,
    'termsAcceptedAt': termsAcceptedAt?.toIso8601String(),
    'termsVersion': termsVersion,
    'termsHash': termsHash,
    'publicationConsentAccepted': publicationConsentAccepted,
    'publicationConsentAcceptedAt':
        publicationConsentAcceptedAt?.toIso8601String(),
    'publicationConsentWithdrawnAt':
        publicationConsentWithdrawnAt?.toIso8601String(),
    'publicationConsentVersion': publicationConsentVersion,
    'publicationConsentHash': publicationConsentHash,
  };

  factory StoreData.fromJson(Map<String, dynamic> json) {
    final parsedGalleryItems = _parseGalleryItems(
      json['galleryItems'] ?? json['gallery_items'],
    );
    final parsedOfferings = _parseOfferings(json['offerings']);

    return StoreData(
      name: _getString(json, 'name') ?? '',
      businessType:
          _getString(json, 'businessType', 'business_type') ?? 'Butik',
      description: _getString(json, 'description') ?? '',
      whatsapp: _getString(json, 'whatsapp') ?? '',
      instagram: _getString(json, 'instagram') ?? '',
      website: _getString(json, 'website') ?? '',
      address: _getString(json, 'address') ?? '',
      theme: _getString(json, 'theme') ?? 'Premium',
      status: _getString(json, 'status') ?? 'Açık',
      slug: _getString(json, 'slug') ?? '',
      isEsnafMode:
          (json['isEsnafMode'] ?? json['is_esnaf_mode'] ?? true) as bool,
      logoUrl: _getString(json, 'logoUrl', 'logo_url'),
      products:
          (json['products'] as List?)
              ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList(),
      marketplaceLinks:
          ((json['marketplaceLinks'] ?? json['marketplace_links']) as List?)
              ?.map((e) => MarketplaceLink.fromJson(e as Map<String, dynamic>))
              .toList(),
      corporateBio: _getString(json, 'corporateBio', 'corporate_bio') ?? '',
      referencesLink:
          _getString(json, 'referencesLink', 'references_link') ?? '',
      shelfImageUrl: _getString(json, 'shelfImageUrl', 'shelf_image_url') ?? '',
      galleryItems: parsedGalleryItems,
      offerings: parsedOfferings,
      isStore: (json['is_store'] ?? json['isStore'] ?? false) as bool,
      kategori: _getString(json, 'kategori', 'category') ?? '',
      workingHours: _getString(json, 'workingHours', 'working_hours') ?? '',
      provinceCode: _getString(json, 'provinceCode', 'province_code') ?? '',
      provinceName: _getString(json, 'provinceName', 'province_name') ?? '',
      districtCode: _getString(json, 'districtCode', 'district_code') ?? '',
      districtName: _getString(json, 'districtName', 'district_name') ?? '',
      googleBusinessLink:
          _getString(json, 'googleBusinessLink', 'google_business_link') ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAccuracyMeters:
          ((json['locationAccuracyMeters'] ?? json['location_accuracy_meters'])
                  as num?)
              ?.toDouble(),
      locationConsentAt: _parseDateTime(
        json['locationConsentAt'] ?? json['location_consent_at'],
      ),
      locationSource: _getString(json, 'locationSource', 'location_source'),
      bookingSettings:
          json['bookingSettings'] != null || json['booking_settings'] != null
              ? BookingSettings.fromJson(
                Map<String, dynamic>.from(
                  (json['bookingSettings'] ?? json['booking_settings']) as Map,
                ),
              )
              : null,
      privacyNoticeAcknowledged:
          (json['privacyNoticeAcknowledged'] ??
                  json['privacy_notice_acknowledged'] ??
                  false)
              as bool,
      privacyNoticeAcknowledgedAt: _parseDateTime(
        json['privacyNoticeAcknowledgedAt'] ??
            json['privacy_notice_acknowledged_at'],
      ),
      privacyNoticeVersion:
          _getString(json, 'privacyNoticeVersion', 'privacy_notice_version') ??
          '',
      privacyNoticeHash:
          _getString(json, 'privacyNoticeHash', 'privacy_notice_hash') ?? '',
      termsAccepted:
          (json['termsAccepted'] ?? json['terms_accepted'] ?? false) as bool,
      termsAcceptedAt: _parseDateTime(
        json['termsAcceptedAt'] ?? json['terms_accepted_at'],
      ),
      termsVersion: _getString(json, 'termsVersion', 'terms_version') ?? '',
      termsHash: _getString(json, 'termsHash', 'terms_hash') ?? '',
      publicationConsentAccepted:
          (json['publicationConsentAccepted'] ??
                  json['publication_consent_accepted'] ??
                  false)
              as bool,
      publicationConsentAcceptedAt: _parseDateTime(
        json['publicationConsentAcceptedAt'] ??
            json['publication_consent_accepted_at'],
      ),
      publicationConsentWithdrawnAt: _parseDateTime(
        json['publicationConsentWithdrawnAt'] ??
            json['publication_consent_withdrawn_at'],
      ),
      publicationConsentVersion:
          _getString(
            json,
            'publicationConsentVersion',
            'publication_consent_version',
          ) ??
          '',
      publicationConsentHash:
          _getString(
            json,
            'publicationConsentHash',
            'publication_consent_hash',
          ) ??
          '',
    );
  }

  /// Mevcut nesnenin bir kopyasını, belirtilen alanlar güncellenmiş
  /// şekilde döner. Değiştirilmek istenmeyen alanlar atlanabilir.
  StoreData copyWith({
    String? name,
    String? businessType,
    String? description,
    String? whatsapp,
    String? instagram,
    String? website,
    String? address,
    String? theme,
    String? status,
    String? slug,
    bool? isEsnafMode,
    String? logoUrl,
    List<Product>? products,
    List<MarketplaceLink>? marketplaceLinks,
    String? corporateBio,
    String? referencesLink,
    String? shelfImageUrl,
    List<StoreGalleryItem>? galleryItems,
    List<StoreOffering>? offerings,
    bool? isStore,
    String? kategori,
    String? workingHours,
    String? provinceCode,
    String? provinceName,
    String? districtCode,
    String? districtName,
    String? googleBusinessLink,
    double? latitude,
    double? longitude,
    double? locationAccuracyMeters,
    DateTime? locationConsentAt,
    String? locationSource,
    BookingSettings? bookingSettings,
    bool? privacyNoticeAcknowledged,
    DateTime? privacyNoticeAcknowledgedAt,
    String? privacyNoticeVersion,
    String? privacyNoticeHash,
    bool? termsAccepted,
    DateTime? termsAcceptedAt,
    String? termsVersion,
    String? termsHash,
    bool? publicationConsentAccepted,
    DateTime? publicationConsentAcceptedAt,
    DateTime? publicationConsentWithdrawnAt,
    String? publicationConsentVersion,
    String? publicationConsentHash,
  }) {
    return StoreData(
      name: name ?? this.name,
      businessType: businessType ?? this.businessType,
      description: description ?? this.description,
      whatsapp: whatsapp ?? this.whatsapp,
      instagram: instagram ?? this.instagram,
      website: website ?? this.website,
      address: address ?? this.address,
      theme: theme ?? this.theme,
      status: status ?? this.status,
      slug: slug ?? this.slug,
      isEsnafMode: isEsnafMode ?? this.isEsnafMode,
      logoUrl: logoUrl ?? this.logoUrl,
      products: products ?? List.of(this.products),
      marketplaceLinks: marketplaceLinks ?? List.of(this.marketplaceLinks),
      corporateBio: corporateBio ?? this.corporateBio,
      referencesLink: referencesLink ?? this.referencesLink,
      shelfImageUrl: shelfImageUrl ?? this.shelfImageUrl,
      galleryItems: galleryItems ?? List.of(this.galleryItems),
      offerings: offerings ?? List.of(this.offerings),
      isStore: isStore ?? this.isStore,
      kategori: kategori ?? this.kategori,
      workingHours: workingHours ?? this.workingHours,
      provinceCode: provinceCode ?? this.provinceCode,
      provinceName: provinceName ?? this.provinceName,
      districtCode: districtCode ?? this.districtCode,
      districtName: districtName ?? this.districtName,
      googleBusinessLink: googleBusinessLink ?? this.googleBusinessLink,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAccuracyMeters:
          locationAccuracyMeters ?? this.locationAccuracyMeters,
      locationConsentAt: locationConsentAt ?? this.locationConsentAt,
      locationSource: locationSource ?? this.locationSource,
      bookingSettings: bookingSettings ?? this.bookingSettings,
      privacyNoticeAcknowledged:
          privacyNoticeAcknowledged ?? this.privacyNoticeAcknowledged,
      privacyNoticeAcknowledgedAt:
          privacyNoticeAcknowledgedAt ?? this.privacyNoticeAcknowledgedAt,
      privacyNoticeVersion: privacyNoticeVersion ?? this.privacyNoticeVersion,
      privacyNoticeHash: privacyNoticeHash ?? this.privacyNoticeHash,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      termsVersion: termsVersion ?? this.termsVersion,
      termsHash: termsHash ?? this.termsHash,
      publicationConsentAccepted:
          publicationConsentAccepted ?? this.publicationConsentAccepted,
      publicationConsentAcceptedAt:
          publicationConsentAcceptedAt ?? this.publicationConsentAcceptedAt,
      publicationConsentWithdrawnAt:
          publicationConsentWithdrawnAt ?? this.publicationConsentWithdrawnAt,
      publicationConsentVersion:
          publicationConsentVersion ?? this.publicationConsentVersion,
      publicationConsentHash:
          publicationConsentHash ?? this.publicationConsentHash,
    );
  }

  // ── Private yardımcılar ───────────────────────────────────────────────

  /// JSON map'inden camelCase ve snake_case olmak üzere iki anahtarı dener.
  static String? _getString(
    Map<String, dynamic> json,
    String camel, [
    String? snake,
  ]) {
    final v = json[camel] ?? (snake != null ? json[snake] : null);
    return v as String?;
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static List<StoreGalleryItem> _parseGalleryItems(Object? rawItems) {
    if (rawItems is! List) return [];

    return rawItems
        .whereType<Map>()
        .map(
          (item) => StoreGalleryItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.imageUrl.trim().isNotEmpty)
        .take(12)
        .toList();
  }

  static List<StoreOffering> _parseOfferings(Object? rawItems) {
    if (rawItems is! List) return [];

    return rawItems
        .whereType<Map>()
        .map((item) => StoreOffering.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.title.trim().isNotEmpty)
        .take(6)
        .toList();
  }

  List<StoreGalleryItem> get displayGalleryItems {
    final validItems =
        galleryItems
            .where((item) => item.imageUrl.trim().isNotEmpty)
            .take(12)
            .toList();

    if (validItems.isNotEmpty) return validItems;

    final legacyImageUrl = shelfImageUrl.trim();
    if (legacyImageUrl.isEmpty) return [];

    return [
      StoreGalleryItem(id: 'legacy-shelf-image', imageUrl: legacyImageUrl),
    ];
  }

  String get coverImageUrl {
    final items = displayGalleryItems;
    return items.isEmpty ? '' : items.first.imageUrl.trim();
  }

  factory StoreData.dummy() {
    return StoreData(
      name: 'Aymira Giyim',
      businessType: 'Kadın giyim / butik',
      description:
          'Raflarımızdaki günlük giyim, elbise, triko ve sezon ürünlerini tek vitrinde inceleyin.',
      whatsapp: '0555 123 45 67',
      instagram: '@aymiragiyim',
      website: 'aymiragiyim.com',
      address: 'Atatürk Cad. No:24, Merkez, İstanbul',
      theme: 'Premium',
      status: 'Açık',
      isEsnafMode: true,
      corporateBio:
          'Aymira Giyim; günlük kombinler, elbise seçenekleri, triko ürünleri ve sezon parçalarını aynı vitrinde sunan yerel bir butik mağazadır. Mağazaya gelmeden önce rafları, reyonları ve öne çıkan ürünleri bu vitrinden inceleyebilirsiniz.',
      referencesLink: 'https://maps.google.com/?q=Aymira+Giyim',
      shelfImageUrl:
          'https://images.unsplash.com/photo-1777628530456-bb93d3a03faf?auto=format&fit=crop&w=1400&q=80',
      galleryItems: [
        StoreGalleryItem(
          id: 'demo-storefront',
          imageUrl:
              'https://images.unsplash.com/photo-1777628530456-bb93d3a03faf?auto=format&fit=crop&w=1400&q=80',
          title: 'Mağaza vitrini',
          description:
              'Sezon ürünleri ve öne çıkan kombinler giriş reyonunda sergilenir.',
        ),
        StoreGalleryItem(
          id: 'demo-shelf',
          imageUrl:
              'https://images.unsplash.com/photo-1761090617068-f1b3257d27ad?auto=format&fit=crop&w=1200&q=80',
          title: 'Yeni sezon reyonu',
          description:
              'Günlük giyim, triko ve rahat kombin seçenekleri tek rafta toplanır.',
        ),
        StoreGalleryItem(
          id: 'demo-dresses',
          imageUrl:
              'https://images.unsplash.com/photo-1767968037382-8eb9c564339f?auto=format&fit=crop&w=1200&q=80',
          title: 'Elbise ve tekstil rafı',
          description:
              'Farklı beden ve renk seçenekleriyle elbise, bluz ve etek ürünleri.',
        ),
        StoreGalleryItem(
          id: 'demo-accessories',
          imageUrl:
              'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?auto=format&fit=crop&w=1200&q=80',
          title: 'Kombin tamamlayıcıları',
          description:
              'Günlük stile eşlik eden tamamlayıcı parçalar ve mağaza düzeni.',
        ),
      ],
      offerings: [
        StoreOffering(
          id: 'demo-offering-1',
          title: 'Yeni Sezon Elbiseler',
          description: 'Şık ve rahat günlük elbise alternatifleri.',
          price: 'Mağazada sorunuz',
        ),
        StoreOffering(
          id: 'demo-offering-2',
          title: 'Kombin Ürünleri',
          description: 'Mevsimlik ceket ve pantolon takımları.',
          price: 'Mağazada sorunuz',
        ),
      ],
      marketplaceLinks: [
        MarketplaceLink(
          id: '1',
          platform: 'Trendyol',
          url: 'trendyol.com/magaza/aymira-giyim',
        ),
        MarketplaceLink(
          id: '2',
          platform: 'Instagram',
          url: 'instagram.com/aymiragiyim',
        ),
        MarketplaceLink(
          id: '3',
          platform: 'Google İşletme',
          url: 'maps.google.com/?q=Aymira+Giyim',
        ),
      ],
      products: [
        Product(
          id: '1',
          name: 'Yeni sezon elbise',
          price: 'Mağazada sorunuz',
          category: 'Elbise',
          description: 'Günlük kullanım ve özel günler için seçilmiş modeller.',
        ),
        Product(
          id: '2',
          name: 'Triko ve günlük kombin',
          price: 'Mağazada sorunuz',
          category: 'Günlük giyim',
          description: 'Raflarda bulunan rahat ve sezonluk kombin seçenekleri.',
        ),
      ],
    );
  }
}

class BookingSettings {
  bool isEnabled;
  int capacity;
  Map<String, dynamic> workingHours;
  Map<String, dynamic> lunchBreak;

  BookingSettings({
    this.isEnabled = false,
    this.capacity = 1,
    Map<String, dynamic>? workingHours,
    Map<String, dynamic>? lunchBreak,
  }) : workingHours =
           workingHours ??
           {
             '1': {'start': '09:00', 'end': '19:00', 'active': true},
             '2': {'start': '09:00', 'end': '19:00', 'active': true},
             '3': {'start': '09:00', 'end': '19:00', 'active': true},
             '4': {'start': '09:00', 'end': '19:00', 'active': true},
             '5': {'start': '09:00', 'end': '19:00', 'active': true},
             '6': {'start': '09:00', 'end': '16:00', 'active': true},
             '7': {'start': '00:00', 'end': '00:00', 'active': false},
           },
       lunchBreak =
           lunchBreak ?? {'start': '12:00', 'end': '13:00', 'active': true};

  Map<String, dynamic> toJson() => {
    'is_enabled': isEnabled,
    'capacity': capacity,
    'working_hours': workingHours,
    'lunch_break': lunchBreak,
  };

  factory BookingSettings.fromJson(Map<String, dynamic> json) {
    return BookingSettings(
      isEnabled: (json['is_enabled'] ?? json['isEnabled'] ?? false) as bool,
      capacity: (json['capacity'] ?? 1) as int,
      workingHours:
          json['working_hours'] != null
              ? Map<String, dynamic>.from(json['working_hours'] as Map)
              : (json['workingHours'] != null
                  ? Map<String, dynamic>.from(json['workingHours'] as Map)
                  : {}),
      lunchBreak:
          json['lunch_break'] != null
              ? Map<String, dynamic>.from(json['lunch_break'] as Map)
              : (json['lunchBreak'] != null
                  ? Map<String, dynamic>.from(json['lunchBreak'] as Map)
                  : {}),
    );
  }
}
