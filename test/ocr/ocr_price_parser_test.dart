import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/ocr/ocr_price_parser.dart';

void main() {
  group('OcrPriceParser', () {
    const parser = OcrPriceParser();

    group('parseAmount', () {
      test('Türk formatında fiyatı ayrıştırır', () {
        expect(parser.parseAmount('15,00'), 15.0);
        expect(parser.parseAmount('1.250,50'), 1250.50);
        expect(parser.parseAmount('99.99'), 99.99);
      });

      test('Para birimi sembolleri ile ayrıştırır', () {
        expect(parser.parseAmount('15,00 ₺'), 15.0);
        expect(parser.parseAmount('TL 25,50'), 25.50);
        expect(parser.parseAmount('TRY 100'), 100.0);
      });

      test('Geçersiz girdiler için null döner', () {
        expect(parser.parseAmount(''), null);
        expect(parser.parseAmount('abc'), null);
        expect(parser.parseAmount('₺'), null);
      });

      test('Sepette ibaresini yok sayar', () {
        expect(parser.parseAmount('sepette 15,00'), 15.0);
        expect(parser.parseAmount('Sepette TL 25,50'), 25.50);
      });
    });

    group('extractPrices', () {
      test('Metin içindeki tüm fiyatları bulur', () {
        final text = 'Ülker Çikolata 15,00 TL\nRulokat 8,50 TL';
        final prices = parser.extractPrices(text);
        expect(prices.length, 2);
        expect(prices[0].amount, 15.0);
        expect(prices[1].amount, 8.5);
      });

      test('Fiyat içermeyen metin için boş liste döner', () {
        final text = 'Bu bir ürün açıklamasıdır';
        final prices = parser.extractPrices(text);
        expect(prices.isEmpty, true);
      });

      test('Saat ve yıldız işaretlerini fiyat olarak algılamaz', () {
        final text = '14:30\n★★★★★';
        final prices = parser.extractPrices(text);
        expect(prices.isEmpty, true);
      });
    });
  });
}
