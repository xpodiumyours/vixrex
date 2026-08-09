# deepseek görevi — UI tutarlılık, Faz 1 (tema + ortak bileşen + 5 örnek ekran)

Bu dosyanın tamamı tek seferde deepseek'e yapıştırılacak prompt'tur.
Aşağıdaki çizginin altındaki her şey kopyalanır.

---

Sen VixRex deposunda çalışıyorsun: `C:\Projects\vixrex`.

VixRex, Türkiye'deki küçük esnaf için hazır dijital vitrin platformu.
İki parça var: `lib/` (Flutter — esnafın işletme paneli) ve `public_web/`
(Next.js 16 — müşterinin gördüğü vitrin, `/v/:slug`).

**Görevin yalnız `lib/` içinde, yalnız görünüm (stil) düzeltmesi.** İş
mantığına, state yönetimine, API çağrılarına dokunmuyorsun — hiçbir ekranın
davranışı değişmeyecek, sadece hepsi aynı görsel dilden konuşacak.

## 1. Önce oku

- `docs/ui-tutarlilik-envanteri.md` — bu görevin dayandığı ölçüm raporu,
  tamamı. Rakamlar ve satır numaraları doğrulandı, güvenebilirsin.
- `lib/main.dart` — mevcut `ThemeData` (satır ~180-300 civarı: `appBarTheme`,
  `cardTheme`, `dialogTheme`)
- `lib/theme/app_colors.dart` — renk ve `radius*` sabitleri
- `lib/theme/app_text_styles.dart` — tanımlı ama neredeyse hiç kullanılmayan
  tipografi sabitleri

## 2. Kesin kurallar

1. **Yalnız `lib/` altına dokun.** `public_web/` ve `supabase/` yasak.
2. **Şu dosyalara dokunma — kasıtlı özel tasarım:**
   - `lib/screens/landing_screen.dart` ve `lib/widgets/landing/*`
   - `lib/theme/vitrin_theme_preset.dart` (müşteri vitrininin 8 tema
     paleti — panel UI'sıyla ilgisi yok, karıştırma)
3. **Görsel değeri uydurma — raporun ölçtüğü baskın değerleri kullan.**
   Yeni bir tasarım icat etmiyorsun, dağınıklığı en çok tekrar eden
   değere topluyorsun. Örnek: `fontSize` için rapordaki en sık geçen
   değerler (12, 13, 14, 16, 18…) taban alınır; köşe yuvarlaklığı için
   en yaygın kullanım neyse o (`AppCard` için rapor 16 öneriyor çünkü en
   sık o).
4. **Davranış değişmeyecek.** Hiçbir `onTap`, state, API çağrısı, koşul
   taşınmıyor/değişmiyor — yalnız `TextStyle(...)` literal'i ortak stile,
   `Container(decoration: BoxDecoration(...))` deseni `AppCard`'a taşınıyor.
5. **Türkçe yaz.** Dosya adları, değişken adları, yorumlar Türkçe. Depo
   baştan sona böyle.
6. **Var olan testleri kırma.** `test/` altında ekranlarla ilgili testler
   var (`explore_screen_test.dart`, `booking_widgets_test.dart` vb.) —
   önce bak, widget ağacını (özellikle `key`, `Text` içeriği) testlerin
   beklediği şekilde bırak.

## 3. Yapılacaklar — sırayla

### A. Temayı tamamla (`lib/main.dart`, `lib/theme/app_text_styles.dart`)

- `appBarTheme`'e `titleTextStyle` ekle: rapordaki en yaygın AppBar başlık
  deseni `TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w900,
  fontSize: 18)` — bkz. `lib/screens/app_settings_screen.dart:232-239` örneği.
- `ThemeData.textTheme`'de şu adlarla standart bir merdiven kur:
  `displayTitle`, `sectionTitle`, `subTitle`, `body`, `caption`, `label`.
  Değerleri raporun 2. bölümündeki (Tipografi Dağılımı) en sık geçen
  boyut/kalınlık eşleşmelerinden türet.
- `lib/theme/app_text_styles.dart`'taki sabitleri bu `textTheme` değerleriyle
  birebir aynı yap (iki kaynak birbirinden sapmasın).

### B. Ortak bileşenler — yeni klasör `lib/widgets/common/`

- **`AppCard`** — `surface` zemin + `radius16` + `border` (rapor 5.
  bölümdeki tekrar eden `Container/BoxDecoration` deseninin yerine geçecek;
  örnek kullanım yerleri: `app_settings`, `booking_management`, `profile`,
  `help_support`, `vitrin_form_section`, `location_editor_section`).
- **`AppSectionHeader`** — bölüm başlığı + açıklama, tek stil.
- **`AppScreenScaffold`** — `AppBar` + zemin rengi (`AppColors.bgEditor`
  standart olsun — rapor 4. bölümde çoğu ekranın zaten bunu kullandığını,
  `home_shell`/`explore`/`bulk_product_upload`'ın farklı olduğunu gösteriyor)
  + güvenli alan + içerik boşluğu tek yerden.

### C. Örnek taşıma — yalnız bu 5 ekran

- `lib/screens/app_settings_screen.dart`
- `lib/screens/notifications_screen.dart`
- `lib/screens/help_support_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/booking_management_screen.dart`

Her birinde: `Scaffold` → `AppScreenScaffold`, AppBar başlığındaki inline
`TextStyle` → temadan gelen stil, tekrar eden kart deseni → `AppCard`,
bölüm başlıkları → `AppSectionHeader`. Ekranın geri kalan iş mantığı
(controller, state, callback) aynen kalır.

## 4. Kapsam dışı — bu turda yapma

- Rapordaki 4. ve 5. adım: kalan ekranlar (`bulk_product_upload`,
  `appointment_tracker`, `explore`, `auth`, `legal`, vitrin form bölümleri)
  ve `xml_upload_dialog.dart`'taki `Colors.red` düzeltmesi. **Bu 5 ekran
  bitip Casper onaylayınca ayrı bir görev olarak verilecek.**
- `lib/widgets/landing/*`, `vitrin_theme_preset.dart` — dokunulmaz.
- Next.js (`public_web`) tarafı — ayrı, bu görevin konusu değil.

## 5. Doğrula

- `flutter analyze` — sıfır hata/uyarı ile bitmeli.
- `flutter test` — özellikle dokunduğun 5 ekranla ilgili testler
  (varsa) geçmeli; genel paket kırılmamalı.
- Değiştirdiğin 5 ekranı `flutter run` ile aç, öncesi/sonrası ekran
  görüntüsü al (aynı cihaz/boyut) — davranış aynı, görünüm tutarlı mı
  gözle teyit et.

## 6. Nasıl rapor ver

İş bitince **kanıtla**, anlatma:
- `flutter analyze` çıktısının tamamı
- `flutter test` çıktısının son 20 satırı (kaç test, kaç geçti)
- Eklediğin/değiştirdiğin dosyaların listesi
- Her 5 ekranın öncesi/sonrası ekran görüntüsü
- Rapordaki bir değeri (fontSize, radius vb.) kendi kararınla farklı
  seçtiysen, hangi değeri neden seçtiğini ayrı yaz — sessizce sapma.

**Uydurma yasak.** Çalıştırmadığın komutun çıktısını yazma; geçmediği
hâlde "geçti" deme. Bir ekranda ortak bileşene taşırken bir şey kırıldıysa
"yapılamadı, şu yüzden" de — yarım işi tam gibi gösterme.

## 7. Takılırsan

- Var olan bir `TextStyle`'ın hangi temaya karşılık geldiği belirsizse
  raporun 2-3. bölümündeki dağılım tablosuna bak, en yakın baskın değeri
  seç — kendi zevkine göre yeni bir değer icat etme.
- Bir ekranda ortak bileşene sığmayan özel bir durum varsa (ör. koşullu
  başlık, özel renk) `AppCard`/`AppScreenScaffold`'u zorlamak yerine not
  al, raporda ayrı başlık altında bildir. Karar Casper'ın.
