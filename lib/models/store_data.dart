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
  };

  factory StoreData.fromJson(Map<String, dynamic> json) {
    final parsedGalleryItems = _parseGalleryItems(
      json['galleryItems'] ?? json['gallery_items'],
    );

    return StoreData(
      name: json['name'] ?? '',
      businessType: json['businessType'] ?? 'Butik',
      description: json['description'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      instagram: json['instagram'] ?? '',
      website: json['website'] ?? '',
      address: json['address'] ?? '',
      theme: json['theme'] ?? 'Premium',
      status: json['status'] ?? 'Açık',
      isEsnafMode: json['isEsnafMode'] ?? true,
      logoUrl: json['logoUrl'],
      products:
          (json['products'] as List?)?.map((e) => Product.fromJson(e)).toList(),
      marketplaceLinks:
          (json['marketplaceLinks'] as List?)
              ?.map((e) => MarketplaceLink.fromJson(e))
              .toList(),
      corporateBio: json['corporateBio'] ?? '',
      referencesLink: json['referencesLink'] ?? '',
      shelfImageUrl: json['shelfImageUrl'] ?? json['shelf_image_url'] ?? '',
      galleryItems: parsedGalleryItems,
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
      name: 'Örnek İşletme',
      businessType: 'Butik / Danışmanlık',
      description: 'Müşterilerimize en iyi hizmeti sunmak için buradayız.',
      whatsapp: '0555 123 45 67',
      instagram: '@isletme',
      address: 'Merkez Mah. No:1, İstanbul',
      theme: 'Premium',
      status: 'Açık',
      isEsnafMode: true,
      corporateBio:
          '2010 yılından beri sektörde öncü çözümler sunuyoruz. Vizyonumuz global pazarda değer yaratmaktır.',
      marketplaceLinks: [
        MarketplaceLink(
          id: '1',
          platform: 'Trendyol',
          url: 'trendyol.com/magaza',
        ),
        MarketplaceLink(
          id: '2',
          platform: 'Hepsiburada',
          url: 'hepsiburada.com/magaza',
        ),
      ],
      products: [
        Product(
          id: '1',
          name: 'Premium Ürün',
          price: '1.250 TL',
          category: 'Yeni',
          description: 'Özel tasarım ürün.',
        ),
        Product(
          id: '2',
          name: 'Standart Hizmet',
          price: '750 TL',
          category: 'Hizmet',
          description: 'Hızlı ve güvenilir.',
        ),
      ],
    );
  }
}
