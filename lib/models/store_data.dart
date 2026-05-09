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
  String theme;
  String status;
  bool isEsnafMode;
  String? logoUrl;
  List<Product> products;

  // Kurumsal Mod Özel Alanları
  String corporateBio;

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
    this.corporateBio = '',
  }) : products = products ?? [];

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
      corporateBio: '2010 yılından beri sektörde öncü çözümler sunuyoruz. Vizyonumuz global pazarda değer yaratmaktır.',
      products: [
        Product(id: '1', name: 'Premium Ürün', price: '1.250 TL', category: 'Yeni', description: 'Özel tasarım ürün.'),
        Product(id: '2', name: 'Standart Hizmet', price: '750 TL', category: 'Hizmet', description: 'Hızlı ve güvenilir.'),
      ],
    );
  }
}
