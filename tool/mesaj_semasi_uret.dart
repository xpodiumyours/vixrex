// shared/vixrex_mesajlar.json → lib/config/vixrex_mesajlar.g.dart
//
// NEDEN VAR (Tek Asistan planı, Faz B)
// Vixrex'in sabit sohbet metinleri yalnız lib/config/chatbot_config.dart
// içinde, elle yazılı satırlar hâlindeydi. Next.js paneli (Faz G) aynı
// kelimeleri kullanacaksa ya kopyalayıp ayrıştıracaktı ya da farklı bir
// tonda yeniden yazacaktı — vitrin alanlarında yaşanan "iki tanım" sorununun
// aynısı.
//
// Artık tek kaynak var: shared/vixrex_mesajlar.json. Oradan hem bu Dart
// dosyası hem de Next.js tarafı (public_web/src/lib/vixrexMesajlari.ts)
// üretiliyor/okunuyor.
//
// Kapsam: yalnız SABİT metin gövdesi. Dinamik olarak birleştirilen
// mesajlar (ör. snapshotWelcome, nextStepTip — çalışma zamanı snapshot'ına
// göre kurulan cümleler) ve hızlı yanıtların aksiyon/payload bağlantıları
// kataloğun dışında, kod tarafında kalır.
//
// ÇALIŞTIRMA
//   dart run tool/mesaj_semasi_uret.dart
//
// Üretilen dosya ELLE DÜZENLENMEZ. Değişiklik şemaya (shared/vixrex_mesajlar.json)
// yazılır, sonra bu betik tekrar çalıştırılır. CI sapma kontrolü ikisinin
// ayrışmasını yakalar (vitrin_alanlari ile aynı mekanizma).

import 'dart:convert';
import 'dart:io';

void main() {
  final kok = Directory.current.path;
  final kaynak = File('$kok/shared/vixrex_mesajlar.json');

  if (!kaynak.existsSync()) {
    stderr.writeln('shared/vixrex_mesajlar.json yok.');
    exit(1);
  }

  final veri = jsonDecode(kaynak.readAsStringSync()) as Map<String, dynamic>;
  final akis = (veri['akis'] as List).cast<Map<String, dynamic>>();
  final intentler = (veri['intentler'] as List).cast<Map<String, dynamic>>();
  final mesajlar = (veri['mesajlar'] as List).cast<Map<String, dynamic>>();

  String dartString(String s) {
    final kacisli = s
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\n')
        .replaceAll(r'$', r'\$');
    return "'$kacisli'";
  }

  final tampon =
      StringBuffer()
        ..writeln('// ÜRETİLMİŞ DOSYA — ELLE DÜZENLEME.')
        ..writeln('//')
        ..writeln('// Kaynak : shared/vixrex_mesajlar.json')
        ..writeln('// Üreten : tool/mesaj_semasi_uret.dart')
        ..writeln('//')
        ..writeln(
          '// Vixrex sohbet asistanının sabit metin kataloğu. Next.js aynı',
        )
        ..writeln('// JSON\'u okur (public_web/src/lib/vixrexMesajlari.ts).')
        ..writeln('')
        ..writeln('class VixRexIntentSemasi {')
        ..writeln('  final String payload;')
        ..writeln('  final List<String> anahtarKelimeler;')
        ..writeln('')
        ..writeln('  const VixRexIntentSemasi({')
        ..writeln('    required this.payload,')
        ..writeln('    required this.anahtarKelimeler,')
        ..writeln('  });')
        ..writeln('}')
        ..writeln('')
        ..writeln(
          '/// Şemadan gelen intent → anahtar kelime eşlemesi. Elle liste',
        )
        ..writeln('/// tutulmaz; yeni bir anahtar kelime şemaya yazılır.')
        ..writeln('const List<VixRexIntentSemasi> vixRexIntentSemasi = [');

  for (final i in intentler) {
    final kelimeler = (i['anahtarKelimeler'] as List)
        .cast<String>()
        .map(dartString)
        .join(', ');
    tampon.writeln('  VixRexIntentSemasi(');
    tampon.writeln("    payload: ${dartString(i['payload'] as String)},");
    tampon.writeln('    anahtarKelimeler: [$kelimeler],');
    tampon.writeln('  ),');
  }

  tampon
    ..writeln('];')
    ..writeln('')
    ..writeln(
      '/// Şemadan gelen sabit mesaj metinleri. Anahtardan hızlı erişim.',
    )
    ..writeln('const Map<String, String> vixRexMesajlari = {');

  for (final m in mesajlar) {
    tampon.writeln(
      "  ${dartString(m['anahtar'] as String)}: ${dartString(m['metin'] as String)},",
    );
  }

  tampon.writeln('};');

  tampon
    ..writeln('')
    ..writeln('class VixRexAsistanAkisAdimi {')
    ..writeln('  final String id;')
    ..writeln('  final List<String> alanlar;')
    ..writeln('  final String mesaj;')
    ..writeln('  final String girdi;')
    ..writeln('  final String? yerTutucu;')
    ..writeln('')
    ..writeln('  const VixRexAsistanAkisAdimi({')
    ..writeln('    required this.id,')
    ..writeln('    required this.alanlar,')
    ..writeln('    required this.mesaj,')
    ..writeln('    required this.girdi,')
    ..writeln('    this.yerTutucu,')
    ..writeln('  });')
    ..writeln('}')
    ..writeln('')
    ..writeln('/// APK, landing ve sahip panelinin ortak kurulum sırası.')
    ..writeln('const List<VixRexAsistanAkisAdimi> vixRexAsistanAkisi = [');

  for (final adim in akis) {
    final alanlar = (adim['alanlar'] as List)
        .cast<String>()
        .map(dartString)
        .join(', ');
    tampon.writeln('  VixRexAsistanAkisAdimi(');
    tampon.writeln("    id: ${dartString(adim['id'] as String)},");
    tampon.writeln('    alanlar: [$alanlar],');
    tampon.writeln("    mesaj: ${dartString(adim['mesaj'] as String)},");
    tampon.writeln("    girdi: ${dartString(adim['girdi'] as String)},");
    if (adim['yerTutucu'] != null) {
      tampon.writeln(
        "    yerTutucu: ${dartString(adim['yerTutucu'] as String)},",
      );
    }
    tampon.writeln('  ),');
  }

  tampon
    ..writeln('];')
    ..writeln('')
    ..writeln(
      'VixRexAsistanAkisAdimi? vixRexAsistanAdimiForAlan(String anahtar) {',
    )
    ..writeln('  for (final adim in vixRexAsistanAkisi) {')
    ..writeln('    if (adim.alanlar.contains(anahtar)) return adim;')
    ..writeln('  }')
    ..writeln('  return null;')
    ..writeln('}');

  final hedef = File('$kok/lib/config/vixrex_mesajlar.g.dart');
  hedef.writeAsStringSync(tampon.toString());

  stdout.writeln('Üretildi: lib/config/vixrex_mesajlar.g.dart');
  stdout.writeln('  intent sayısı : ${intentler.length}');
  stdout.writeln('  mesaj sayısı  : ${mesajlar.length}');
  stdout.writeln('  akış adımı    : ${akis.length}');
}
