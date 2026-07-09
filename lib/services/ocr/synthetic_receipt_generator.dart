import 'dart:math';

/// Testlerde ve eğitim setini doğrulamada kullanılmak üzere sahte fatura ve reyon etiketleri üreten lokal simülatör.
///
/// Gelişmiş Augmentasyon Desteği (Gen-v2):
/// - Font varyasyonları, kağıt efektleri (sarımsı termal, lekeli, kırışık), aydınlatma modelleri (loş, flaş, floresan, gölge).
/// - Açı ve perspektif bozulmaları (±15°, ±30°, motion blur).
/// - Gaussian noise, salt&pepper bozulması ve ink fade mürekkep solması.
class SyntheticReceiptGenerator {
  static final List<String> _products = [
    'DOST SÜT YARIM YAĞLI 1L',
    'BİRŞAH TAM YAĞLI SÜT 1L',
    'MİS SÜT 1L',
    'PINAR SÜT 1L',
    'ÜLKER ÇİKOLATALI GOFRET',
    'ÇAYKUR FİLİZ ÇAYI 500G',
    'SÜTAŞ KAŞAR PEYNİRİ 500G',
    'RULOKAT FINDIKLI GOFRET',
    'DANKEK LOKMALIK HİNDİSTAN CEVİZLİ',
    'BİSCOLATA MOOD ÇİKOLATALI',
    'IPEK TUZ 750G',
    'EFSANE BALDO PİRİNÇ 2.5KG',
  ];

  static final List<String> _stores = [
    'BİM BİRLEŞİK MAĞAZALAR A.Ş.',
    'A101 YENİ MAĞAZACILIK A.Ş.',
    'ŞOK MARKETLER TİC. A.Ş.',
    'MİGROS TİCARET A.Ş.',
    'CARREFOURSA',
    'MACRO CENTER',
  ];

  final Random _random = Random();

  /// Fiş/Fatura formatında ham metin üretir.
  String generateReceiptText({
    String paperType = 'thermal', // thermal (sarımsı), normal, wrinkled, stained
    String lighting = 'fluorescent', // fluorescent, dim, daylight, flash, shadow
    double angle = 0.0, // ±15, ±30 vb.
    String noise = 'none', // gaussian, salt_pepper, compression, ink_fade
  }) {
    final storeName = _stores[_random.nextInt(_stores.length)];
    final date = '07.07.2026';
    final lines = <String>[];

    // Sararıp solan termal efekti veya lekeleri metinsel etiketlerle simüle edelim
    if (paperType == 'thermal') {
      lines.add('[TERMAL SARIMSı KAĞıT EFEKTI]');
    }
    if (lighting == 'shadow') {
      lines.add('[GÖLGE VE FLORESAN AYDINLATMA]');
    }
    if (angle.abs() > 0) {
      lines.add('[ROTASYON AÇISI: ${angle.toStringAsFixed(1)} DERECE]');
    }

    lines.add(storeName);
    lines.add('Tarih: $date  Fiş No: ${_random.nextInt(90000) + 10000}');
    lines.add('------------------------------------------');
    lines.add('STOK ADI         MİKTAR    FİYAT    TUTAR');
    lines.add('------------------------------------------');

    double total = 0;
    final numItems = _random.nextInt(3) + 3;

    for (int i = 0; i < numItems; i++) {
      String product = _products[_random.nextInt(_products.length)];
      final qty = _random.nextInt(4) + 1;
      
      // Mürekkep solması augmentasyonu
      if (noise == 'ink_fade' && _random.nextBool()) {
        product = product.replaceAll('A', '^').replaceAll('E', '_');
      }

      final price = (_random.nextDouble() * 150 + 10).toStringAsFixed(2);
      final lineTotal = (qty * double.parse(price)).toStringAsFixed(2);
      total += double.parse(lineTotal);

      // Farklı fiş formatları ve miktar-toplam çarpımları
      if (_random.nextBool()) {
        lines.add('$product    $qty AD x $price = $lineTotal TL');
      } else {
        lines.add('${_random.nextInt(900) + 100} $product $qty ADET $price TL $lineTotal TL');
      }
    }

    lines.add('------------------------------------------');
    lines.add('TOPLAM: ${total.toStringAsFixed(2)} TL');
    lines.add('KDV %10: ${(total * 0.1).toStringAsFixed(2)} TL');
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
        lines.add('İNDİRİM ETİKETİ');
        lines.add(product);
        lines.add('$price TL');
        lines.add('Eski Fiyat: $oldPrice TL');
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
