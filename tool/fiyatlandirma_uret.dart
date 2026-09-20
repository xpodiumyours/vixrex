// shared/fiyatlandirma.json → lib/config/fiyatlandirma.g.dart
// Çalıştırma: dart run tool/fiyatlandirma_uret.dart

import 'dart:convert';
import 'dart:io';

String quote(String value) => "'${value.replaceAll("'", r"\'")}'";

String fiyatMetni(int kurus, String simge) {
  final tamKisim = kurus ~/ 100;
  final kurusKisim = kurus % 100;
  if (kurusKisim == 0) {
    return '$tamKisim $simge';
  }
  final ondalik = kurusKisim.toString().padLeft(2, '0');
  return '$tamKisim,$ondalik $simge';
}

String kalipDoldur(String kalip, String fiyat, String aylikBedel) =>
    kalip.replaceAll('{aylikBedel}', aylikBedel).replaceAll('{fiyat}', fiyat);

void main() {
  final root = Directory.current.path;
  final source = File('$root/shared/fiyatlandirma.json');
  final decoded = jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;

  final kurus = decoded['aylikPremiumKurus'] as int;
  final paraBirimi = decoded['paraBirimi'] as String;
  final simge = decoded['paraBirimiSimgesi'] as String;
  final kaliplar = (decoded['metinKaliplari'] as Map).cast<String, dynamic>();

  if (kurus <= 0) {
    throw StateError('Aylık premium bedeli pozitif kuruş olmalı.');
  }

  final fiyat = fiyatMetni(kurus, simge);
  final aylikBedel = kalipDoldur(kaliplar['aylikBedel'] as String, fiyat, '');

  String metin(String anahtar) =>
      kalipDoldur(kaliplar[anahtar] as String, fiyat, aylikBedel);

  final buffer =
      StringBuffer()
        ..writeln('// shared/fiyatlandirma.json dosyasından üretildi.')
        ..writeln('// ELLE DÜZENLENMEZ — dart run tool/fiyatlandirma_uret.dart')
        ..writeln()
        ..writeln('/// Aylık premium bedeli, kuruş.')
        ..writeln('const int aylikPremiumKurus = $kurus;')
        ..writeln()
        ..writeln('/// Para birimi kodu (PayTR ve yapısal veri için).')
        ..writeln('const String paraBirimi = ${quote(paraBirimi)};')
        ..writeln()
        ..writeln('/// Görüntülenen bedel, ör. 299 TL.')
        ..writeln('const String aylikPremiumFiyat = ${quote(fiyat)};')
        ..writeln()
        ..writeln('/// Aylık bedel cümlesi, ör. Aylık 299 TL.')
        ..writeln('const String aylikPremiumBedel = ${quote(aylikBedel)};')
        ..writeln()
        ..writeln('/// Premium olmayan vitrin kartı rozeti.')
        ..writeln(
          'const String premiumDegilRozet = ${quote(metin('premiumDegilRozet'))};',
        )
        ..writeln()
        ..writeln('/// Yayın çağrısı düğmesi.')
        ..writeln(
          'const String premiumIleYayinla = ${quote(metin('premiumIleYayinla'))};',
        )
        ..writeln()
        ..writeln('/// Yayın kapısı uyarısı.')
        ..writeln(
          'const String yayinKapisiUyarisi = ${quote(metin('yayinKapisiUyarisi'))};',
        );

  File(
    '$root/lib/config/fiyatlandirma.g.dart',
  ).writeAsStringSync(buffer.toString());

  stdout.writeln('aylık premium: $fiyat ($kurus kuruş, $paraBirimi)');
  stdout.writeln('rozet: ${metin('premiumDegilRozet')}');
}
