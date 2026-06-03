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
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    price: json['price'] ?? '',
    description: json['description'] ?? '',
    imagePath: json['imagePath'],
    category: json['category'] ?? 'Tümü',
    stockStatus: json['stockStatus'] ?? 'Mevcut',
  );
}

class MarketplaceLink {
  String id;
  String platform; // 'Trendyol', 'Hepsiburada', 'N11', 'Diğer'
  String url;

  MarketplaceLink({
    required this.id,
    this.platform = 'Trendyol',
    this.url = '',
  });

  Map<String, dynamic> toJson() => {'id': id, 'platform': platform, 'url': url};

  factory MarketplaceLink.fromJson(Map<String, dynamic> json) =>
      MarketplaceLink(
        id: json['id'] ?? '',
        platform: json['platform'] ?? 'Trendyol',
        url: json['url'] ?? '',
      );
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
  bool isStore;
  String kategori;

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
    this.isEsnafMode = true,
    this.logoUrl,
    List<Product>? products,
    List<MarketplaceLink>? marketplaceLinks,
    this.corporateBio = '',
    this.referencesLink = '',
    this.shelfImageUrl = '',
    List<StoreGalleryItem>? galleryItems,
    this.isStore = false,
    this.kategori = '',
    this.latitude,
    this.longitude,
    this.locationAccuracyMeters,
    this.locationConsentAt,
    this.locationSource,
  }) : products = products ?? [],
       marketplaceLinks = marketplaceLinks ?? [MarketplaceLink(id: '1')],
       galleryItems = galleryItems ?? [];

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
    'isEsnafMode': isEsnafMode,
    'logoUrl': logoUrl,
    'products': products.map((e) => e.toJson()).toList(),
    'marketplaceLinks': marketplaceLinks.map((e) => e.toJson()).toList(),
    'corporateBio': corporateBio,
    'referencesLink': referencesLink,
    'shelfImageUrl': shelfImageUrl,
    'galleryItems': galleryItems.map((e) => e.toJson()).toList(),
    'isStore': isStore,
    'kategori': kategori,
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

    return StoreData(
      name: json['name'] ?? '',
      businessType: json['businessType'] ?? json['business_type'] ?? 'Butik',
      description: json['description'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      instagram: json['instagram'] ?? '',
      website: json['website'] ?? '',
      address: json['address'] ?? '',
      theme: json['theme'] ?? 'Premium',
      status: json['status'] ?? 'Açık',
      isEsnafMode: json['isEsnafMode'] ?? json['is_esnaf_mode'] ?? true,
      logoUrl: json['logoUrl'] ?? json['logo_url'],
      products:
          (json['products'] as List?)?.map((e) => Product.fromJson(e)).toList(),
      marketplaceLinks:
          (json['marketplaceLinks'] as List?)
              ?.map((e) => MarketplaceLink.fromJson(e))
              .toList() ?? (json['marketplace_links'] as List?)
              ?.map((e) => MarketplaceLink.fromJson(e))
              .toList(),
      corporateBio: json['corporateBio'] ?? json['corporate_bio'] ?? '',
      referencesLink: json['referencesLink'] ?? json['references_link'] ?? '',
      shelfImageUrl: json['shelfImageUrl'] ?? json['shelf_image_url'] ?? '',
      galleryItems: parsedGalleryItems,
      isStore: json['is_store'] ?? json['isStore'] ?? false,
      kategori: json['kategori'] ?? json['category'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAccuracyMeters: (json['locationAccuracyMeters'] ?? json['location_accuracy_meters'] as num?)?.toDouble(),
      locationConsentAt: json['locationConsentAt'] != null || json['location_consent_at'] != null
          ? DateTime.tryParse((json['locationConsentAt'] ?? json['location_consent_at']) as String)
          : null,
      locationSource: json['locationSource'] ?? json['location_source'] as String?,
    );
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
