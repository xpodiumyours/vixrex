class StoreOffering {
  String id;
  String title;
  String description;
  String price;
  String currency; // Para birimi (varsayılan: TRY)
  int durationMinutes; // Dakika cinsinden (varsayılan 30, 15-240 arası)
  bool isBookable; // Randevuya açık mı?

  StoreOffering({
    required this.id,
    this.title = '',
    this.description = '',
    this.price = '',
    this.currency = 'TRY',
    this.durationMinutes = 30,
    this.isBookable = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'currency': currency,
    'durationMinutes': durationMinutes,
    'isBookable': isBookable,
  };

  factory StoreOffering.fromJson(Map<String, dynamic> json) => StoreOffering(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    price: (json['price'] ?? '').toString(),
    currency: (json['currency'] ?? 'TRY').toString(),
    durationMinutes:
        (json['durationMinutes'] ?? json['duration_minutes'] ?? 30) as int,
    isBookable: (json['isBookable'] ?? json['is_bookable'] ?? false) as bool,
  );

  StoreOffering copyWith({
    String? id,
    String? title,
    String? description,
    String? price,
    String? currency,
    int? durationMinutes,
    bool? isBookable,
  }) {
    return StoreOffering(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isBookable: isBookable ?? this.isBookable,
    );
  }

  /// Fiyatı para birimiyle birlikte göster.
  String get formattedPrice {
    if (price.isEmpty) return '';
    return '$price $currency';
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
