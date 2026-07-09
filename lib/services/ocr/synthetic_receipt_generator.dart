import 'dart:math';

/// Testlerde ve eğitim setini doğrulamada kullanılmak üzere sahte fatura ve raf etiketleri üreten lokal simülatör.
class SyntheticReceiptGenerator {
  static final List<String> _products = [
    'V YAKA KISA KOL BADİ',
    'YAKASI KISA KOL REÇME ARA BİYELİ',
    'TUT BYN BADY SÜTYEN',
    'Dankek Lokmalık Hindistan Cevizli',
    'Biscolata Mood Çikolatalı',
    'Kekstra Çilekli Jolebol',
    'Ülker Çokoprens',
    'Luppo Sandviç Kek',
    'Çaykur Filiz Çayı 500g',
    'Sütaş Tam Yağlı Süt 1L',
    'Ülker Çikolatalı Gofret',
    'Rulokat Fındıklı Rulo Gofret',
  ];

  static final List<String> _stores = [
    'ECE SİPARİŞ TEKLİF FORMU',
    'BELISSA MODA',
    'P.N.R Collection',
    'KİM MARKET',
    'BİZİM BAKKAL',
  ];

  final Random _random = Random();

  /// Fiş/Fatura formatında ham metin üretir.
  String generateReceiptText() {
    final storeName = _stores[_random.nextInt(_stores.length)];
    final date = '07.07.2026';
    final lines = <String>[];

    lines.add(storeName);
    lines.add('Tarih: $date  Fiş No: ${_random.nextInt(90000) + 10000}');
    lines.add('------------------------------------------');
    lines.add('STOK ADI         MİKTAR    FİYAT    TUTAR');
    lines.add('------------------------------------------');

    double total = 0;
    final numItems = _random.nextInt(3) + 2;

    for (int i = 0; i < numItems; i++) {
      final product = _products[_random.nextInt(_products.length)];
      final qty = _random.nextInt(4) + 1;
      final price = (_random.nextDouble() * 150 + 10).toStringAsFixed(2);
      final lineTotal = (qty * double.parse(price)).toStringAsFixed(2);
      total += double.parse(lineTotal);

      // Farklı fiş formatları simüle ediliyor
      if (_random.nextBool()) {
        lines.add('$product    $qty AD    $price    $lineTotal');
      } else {
        lines.add('${_random.nextInt(900) + 100} $product $qty ADET $price TL $lineTotal TL');
      }
    }

    lines.add('------------------------------------------');
    lines.add('TOPLAM: ${total.toStringAsFixed(2)} TL');
    lines.add('KDV: ${(total * 0.1).toStringAsFixed(2)} TL');
    lines.add('GENEL TOPLAM: ${(total * 1.1).toStringAsFixed(2)} TL');

    return lines.join('\n');
  }

  /// Raf etiketlerinden taranmış gibi ham metin üretir.
  String generateShelfLabelText() {
    final lines = <String>[];
    final numLabels = _random.nextInt(3) + 2;

    for (int i = 0; i < numLabels; i++) {
      final product = _products[_random.nextInt(_products.length)];
      final price = (_random.nextDouble() * 80 + 10).toStringAsFixed(2);

      // İndirimli veya standart fiyat etiketleri simüle ediliyor
      final dice = _random.nextInt(3);
      if (dice == 0) {
        // Sarı İndirim Etiketi formatı
        final oldPrice = (double.parse(price) * 1.25).toStringAsFixed(2);
        lines.add('KİM seni düşünür İNDİRİM');
        lines.add(product);
        lines.add('$price TL');
        lines.add('Eski Fiyat: $oldPrice TL');
      } else if (dice == 1) {
        // Biscolata tarzı reyon etiketi
        lines.add(product);
        lines.add('İNDİRİM');
        lines.add(price);
        lines.add('DİĞER: 0.00');
      } else {
        // Standart beyaz etiket
        lines.add(product);
        lines.add('Fiyat: $price ₺');
        lines.add('KDV Dahil');
      }
      lines.add('=======================');
    }

    return lines.join('\n');
  }
}
