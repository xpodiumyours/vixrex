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
}

class StoreData {
  String name;
  String businessType;
  String description;
  String whatsapp;
  String instagram;
  String website;
  String salesLink;
  String address;
  String theme; // Sade, Premium, Zarif, Doğal, Gece, Lüks, Sahil, Güneş
  String status; // Açık, Bugün kampanya var, Yeni ürünler geldi, Stok sınırlı
  bool isEsnafMode; // Esnaf Modu vs Kurumsal Mod
  String? logoUrl;
  List<Product> products;

  StoreData({
    this.name = '',
    this.businessType = 'Butik',
    this.description = '',
    this.whatsapp = '',
    this.instagram = '',
    this.website = '',
    this.salesLink = '',
    this.address = '',
    this.theme = 'Sade',
    this.status = 'Açık',
    this.isEsnafMode = true,
    this.logoUrl,
    List<Product>? products,
  }) : products = products ?? [];

  factory StoreData.dummy() {
    return StoreData(
      name: 'Örnek Mağaza',
      businessType: 'Butik',
      description: 'Harika ürünlerimizi ve yeni koleksiyonlarımızı keşfedin.',
      whatsapp: '0555 123 45 67',
      instagram: '@magazakullanici',
      address: 'Merkez Mah. İstiklal Cad. No:1, İstanbul',
      theme: 'Premium',
      status: 'Yeni ürünler geldi',
      isEsnafMode: true,
      products: [
        Product(
          id: '1',
          name: 'Klasik Gömlek',
          price: '450 TL',
          description: 'Pamuklu, rahat kesim.',
          category: 'Üst Giyim',
        ),
        Product(
          id: '2',
          name: 'Şık Pantolon',
          price: '750 TL',
          description: 'Keten kumaş, modern tasarım.',
          category: 'Alt Giyim',
        ),
      ],
    );
  }
}
