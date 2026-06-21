class Product {
  String id;
  String name;
  String price;
  String description;
  String? imagePath;
  String category;
  String stockStatus; // 'Mevcut', 'Tükendi', 'Son birkaç adet'

  Product({
    required this.id,
    this.name = '',
    this.price = '',
    this.description = '',
    this.imagePath,
    this.category = 'Tümü',
    this.stockStatus = 'Mevcut',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'description': description,
    'imagePath': imagePath,
    'category': category,
    'stockStatus': stockStatus,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    price: (json['price'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    imagePath: json['imagePath'] as String?,
    category: (json['category'] ?? 'Tümü').toString(),
    stockStatus: (json['stockStatus'] ?? 'Mevcut').toString(),
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
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      stockStatus: stockStatus ?? this.stockStatus,
    );
  }
}

class MarketplaceLink {
  String id;
  String platform; // 'Trendyol', 'Hepsiburada', 'N11', 'Diğer', ya da özel başlık
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

  StoreOffering({
    required this.id,
    this.title = '',
    this.description = '',
    this.price = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
  };

  factory StoreOffering.fromJson(Map<String, dynamic> json) => StoreOffering(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    price: (json['price'] ?? '').toString(),
  );

  StoreOffering copyWith({
    String? id,
    String? title,
    String? description,
    String? price,
  }) {
    return StoreOffering(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
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

  // Konum ve KVKK Alanları
  double? latitude;
  double? longitude;
  double? locationAccuracyMeters;
  DateTime? locationConsentAt;
  String? locationSource;

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
    this.latitude,
    this.longitude,
    this.locationAccuracyMeters,
    this.locationConsentAt,
    this.locationSource,
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
    'latitude': latitude,
    'longitude': longitude,
    'locationAccuracyMeters': locationAccuracyMeters,
    'locationConsentAt': locationConsentAt?.toIso8601String(),
    'locationSource': locationSource,
  };

  factory StoreData.fromJson(Map<String, dynamic> json) {
    final parsedGalleryItems = _parseGalleryItems(
      json['galleryItems'] ?? json['gallery_items'],
    );
    final parsedOfferings = _parseOfferings(
      json['offerings'],
    );

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
    double? latitude,
    double? longitude,
    double? locationAccuracyMeters,
    DateTime? locationConsentAt,
    String? locationSource,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAccuracyMeters:
          locationAccuracyMeters ?? this.locationAccuracyMeters,
      locationConsentAt: locationConsentAt ?? this.locationConsentAt,
      locationSource: locationSource ?? this.locationSource,
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
        .map(
          (item) => StoreOffering.fromJson(Map<String, dynamic>.from(item)),
        )
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
