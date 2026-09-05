import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/store_location_fetch_service.dart';

void main() {
  const servis = StoreLocationFetchService();

  test('il ve ilçe birlikte geçen adreste ikisi de eşleşir', () {
    final sonuc = servis.eslestirIlIlce(
      'Çatalmeşe Mahallesi, 208. Sokak, Çekmeköy, İstanbul',
    );
    expect(sonuc.provinceCode, '34');
    expect(sonuc.provinceName, 'İstanbul');
    expect(sonuc.districtName, 'Çekmeköy');
  });

  test('benzersiz ilçe il yazılmasa da canonical ilini belirler', () {
    final sonuc = servis.eslestirIlIlce('Kadıköy Rıhtım Caddesi');
    expect(sonuc.provinceCode, '34');
    expect(sonuc.provinceName, 'İstanbul');
    expect(sonuc.districtName, 'Kadıköy');
  });

  test('yalnız il geçen adreste ilçe null döner, il yine de eşleşir', () {
    final sonuc = servis.eslestirIlIlce('Merkez, İstanbul');
    expect(sonuc.provinceCode, '34');
    expect(sonuc.districtName, isNull);
  });

  test('ambiguous Kemer il belirtilmeden tahmin edilmez', () {
    final sonuc = servis.eslestirIlIlce('Kemer merkezindeki işletmem');
    expect(sonuc.provinceCode, isNull);
    expect(sonuc.provinceName, isNull);
    expect(sonuc.districtName, isNull);
  });

  test('ambiguous Kemer il ile birlikte doğru çifte çözülür', () {
    final antalya = servis.eslestirIlIlce('Kemer, Antalya');
    expect(antalya.provinceCode, '07');
    expect(antalya.provinceName, 'Antalya');
    expect(antalya.districtName, 'Kemer');

    final burdur = servis.eslestirIlIlce('Kemer, Burdur');
    expect(burdur.provinceCode, '15');
    expect(burdur.provinceName, 'Burdur');
    expect(burdur.districtName, 'Kemer');
  });

  test('alt-dize il eşleşmesi yapılmaz', () {
    final sonuc = servis.eslestirIlIlce('Vangölü kıyısında bir işletme');
    expect(sonuc.provinceCode, isNull);
    expect(sonuc.provinceName, isNull);
    expect(sonuc.districtName, isNull);
  });

  test('hiçbir il geçmeyen adreste hepsi null döner', () {
    final sonuc = servis.eslestirIlIlce('Bilinmeyen bir sokak, Marslılar');
    expect(sonuc.provinceCode, isNull);
    expect(sonuc.provinceName, isNull);
    expect(sonuc.districtName, isNull);
  });

  test('Türkçe karakter/büyük-küçük harf farkı eşleşmeyi bozmaz', () {
    final sonuc = servis.eslestirIlIlce('ŞIŞLI, ISTANBUL');
    expect(sonuc.provinceCode, '34');
    expect(sonuc.districtName, 'Şişli');
  });

  test('kelime sınırı korunurken gerçek ilçe adı doğru eşleşir', () {
    final sonuc = servis.eslestirIlIlce(
      'Halaskargazi Caddesi, Şişli, İstanbul',
    );
    expect(sonuc.districtName, 'Şişli');
  });
}
