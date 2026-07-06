import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/models/store_offering.dart';
import 'package:vixrex/models/working_hours.dart';
import 'package:vixrex/models/store_data_dto.dart';

export 'package:vixrex/models/store_product.dart';
export 'package:vixrex/models/store_offering.dart';
export 'package:vixrex/models/working_hours.dart';

class StoreData {
  String? id;
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
  List<ProductCategory> productCategories;
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
    this.id,
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
    List<ProductCategory>? productCategories,
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
       productCategories = productCategories ?? [],
       marketplaceLinks = marketplaceLinks ?? [MarketplaceLink(id: '1')],
       galleryItems = galleryItems ?? [],
       offerings = offerings ?? [];

  Map<String, dynamic> toJson() => StoreDataDto.toJson(this);

  factory StoreData.fromJson(Map<String, dynamic> json) => StoreDataDto.fromJson(json);

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
    List<ProductCategory>? productCategories,
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
      id: id,
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
      productCategories: productCategories ?? List.of(this.productCategories),
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
      locationAccuracyMeters: locationAccuracyMeters ?? this.locationAccuracyMeters,
      locationConsentAt: locationConsentAt ?? this.locationConsentAt,
      locationSource: locationSource ?? this.locationSource,
      bookingSettings: bookingSettings ?? this.bookingSettings,
      privacyNoticeAcknowledged: privacyNoticeAcknowledged ?? this.privacyNoticeAcknowledged,
      privacyNoticeAcknowledgedAt: privacyNoticeAcknowledgedAt ?? this.privacyNoticeAcknowledgedAt,
      privacyNoticeVersion: privacyNoticeVersion ?? this.privacyNoticeVersion,
      privacyNoticeHash: privacyNoticeHash ?? this.privacyNoticeHash,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      termsVersion: termsVersion ?? this.termsVersion,
      termsHash: termsHash ?? this.termsHash,
      publicationConsentAccepted: publicationConsentAccepted ?? this.publicationConsentAccepted,
      publicationConsentAcceptedAt: publicationConsentAcceptedAt ?? this.publicationConsentAcceptedAt,
      publicationConsentWithdrawnAt: publicationConsentWithdrawnAt ?? this.publicationConsentWithdrawnAt,
      publicationConsentVersion: publicationConsentVersion ?? this.publicationConsentVersion,
      publicationConsentHash: publicationConsentHash ?? this.publicationConsentHash,
    );
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

  set coverImageUrl(String value) {
    shelfImageUrl = value;
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
