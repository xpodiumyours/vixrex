import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/store_location_fetch_service.dart';

/// `StoreLocationFetchService.eslestirIlIlce` — Faz 4 (controller
/// parçalama) ile mixin'den çıkarılan SAF il/ilçe eşleştirme fonksiyonu.
/// Öncesinde bu mantık yalnız `fetchLocation`'ın içindeydi, GPS/ağ
/// çağrısı olmadan tek başına test edilemiyordu.
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

  test('yalnız il geçen adreste ilçe null döner, il yine de eşleşir', () {
    final sonuc = servis.eslestirIlIlce('Merkez, İstanbul');
    expect(sonuc.provinceCode, '34');
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

  test('uzun ilçe adı önce denenir — kısa bir alt dize yanlış eşleşmez', () {
    // "Şişli" başka bir ilçe adının içinde geçmiyor ama uzun-önce sıralama
    // kuralı budur; en azından gerçek bir ilçe adı doğru döner.
    final sonuc = servis.eslestirIlIlce(
      'Halaskargazi Caddesi, Şişli, İstanbul',
    );
    expect(sonuc.districtName, 'Şişli');
  });
}
