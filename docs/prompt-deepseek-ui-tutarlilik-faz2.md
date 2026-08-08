# deepseek görevi — UI tutarlılık, Faz 2 (kalan ekranlar + tekil düzeltmeler)

Bu dosyanın tamamı tek seferde deepseek'e yapıştırılacak prompt'tur.
Aşağıdaki çizginin altındaki her şey kopyalanır.

---

Sen VixRex deposunda çalışıyorsun: `C:\Projects\vixrex`.

**Önce bunu yap:** `git checkout tasarim/ui-tutarlilik-faz1` — bu senin Faz 1'de
açtığın dal, commit `4d68723` ile GitHub'a gönderildi (PR #66, **henüz main'e
birleşmedi**, birleşmeyecek de — sen bu dala işlemeye devam edeceksin). Faz 1
zaten bu dalda: `lib/widgets/common/` (AppCard, AppSectionHeader,
AppScreenScaffold) ve `lib/main.dart`'taki `textTheme`/`appBarTheme` hazır.
**Sıfırdan başlamıyorsun — devam ediyorsun.**

VixRex, Türkiye'deki küçük esnaf için hazır dijital vitrin platformu.
`lib/` = Flutter işletme paneli, `public_web/` = müşterinin gördüğü vitrin.
**Görevin yalnız `lib/`'de, yalnız görünüm (stil) düzeltmesi** — iş mantığına
dokunmuyorsun.

## 1. Önce oku

- `docs/ui-tutarlilik-envanteri.md` — ölçüm raporu (Faz 1'de kullandığın
  aynı rapor, madde 4 ve 5 şimdi sıra sende)
- Kendi yazdığın `lib/widgets/common/app_card.dart`,
  `app_section_header.dart`, `app_screen_scaffold.dart` — bunları
  **tekrar yazma, kullan**
- `lib/main.dart`'taki `textTheme` tanımı — hangi isim hangi boyuta
  karşılık geliyor, oradan oku

## 2. Kesin kurallar (Faz 1 ile aynı)

1. Yalnız `lib/` altına dokun. `public_web/` ve `supabase/` yasak.
2. Dokunma: `lib/screens/landing_screen.dart`, `lib/widgets/landing/*`,
   `lib/theme/vitrin_theme_preset.dart`.
3. Değer icat etme — rapordaki baskın değerleri veya Faz 1'de kurduğun
   `AppTextStyles`/`AppColors.radius*` sabitlerini kullan.
4. Davranış değişmeyecek, yalnız görünüm.
5. Türkçe yaz.
6. `flutter test`'i kırma — özellikle dokunduğun ekranlarla ilgili
   testler varsa önce oku.
7. **Kapsam dışı bir şey görürsen dokunma, not al.** Örnek: tema seçici
   (`store_theme_picker.dart`) yanlış sütuna yazıyor — bu ayrı, veri
   hatası, bu görevin konusu değil.

## 3. Yapılacaklar

### A. Kalan tekil ekranlar

- `lib/screens/bulk_product_upload_screen.dart` (rapor: 27 inline TextStyle — en yoğun dosya)
- `lib/screens/appointment_tracker_screen.dart`
- `lib/screens/explore_screen.dart`
- `lib/screens/auth_screen.dart`
- `lib/screens/legal_screen.dart`

Faz 1'deki 5 ekranda uyguladığın aynı desen: `Scaffold` →
`AppScreenScaffold` (uymuyorsa, ör. `explore_screen.dart`'ın kendi sekme
yapısı varsa zorlama, yalnız zemin rengini ve başlık stilini düzelt),
tekrar eden kart deseni → `AppCard`, bölüm başlıkları → `AppSectionHeader`.

### B. Vitrin form bölümleri

- `lib/screens/my_vitrin/` altındaki tüm dosyalar (`vitrin_form_section.dart` — 13 TextStyle)
- `lib/widgets/editor/` altındaki tüm dosyalar — en yoğunlar:
  `location_editor_section.dart` (24), `working_hours_editor.dart` (15),
  `marketplace_links_section.dart` (11), `gallery_editor_section.dart` (9),
  `visibility_hub_card.dart` (9)

Bunlar form alanları (input/picker), `AppCard`/`AppSectionHeader` her
yerde uymayabilir — uymuyorsa yalnız `TextStyle` literallerini
`AppTextStyles` sabitlerine çek, zorla bileşen değiştirme.

### C. Tekil düzeltmeler

1. `lib/widgets/xml_upload_dialog.dart:117` — `Colors.red` → `AppColors.error`
2. **Zemin tutarsızlığı:** `lib/screens/home_shell_screen.dart`,
   `lib/screens/explore_screen.dart`, `lib/screens/bulk_product_upload_screen.dart`
   şu an `AppColors.surface` kullanıyor, geri kalan ekranların hepsi
   `AppColors.bgEditor` — bu üçünü `bgEditor`'e çek. `home_shell_screen.dart`
   alt gezinme iskeleti olduğu için `AppScreenScaffold`'a sarmaya
   **çalışma**, yalnız zemin rengini düzelt.
3. **Köşe yuvarlaklığı:** rapordaki tanımsız literal değerleri (14, 10,
   20 gibi) `AppColors.radius12/16/20/24/30/40` sabitlerine veya
   uygun yerlerde `AppCard`'a çek.

## 4. Kapsam dışı — bu turda da yapma

- `lib/widgets/landing/*`, `vitrin_theme_preset.dart`, `public_web/`.
- `store_theme_picker.dart`'ın yazdığı sütun hatası (veri katmanı, ayrı görev).
- Vixrex Asistan sohbet ekranı (`vixrex_onboarding_chat_screen.dart`,
  `vixrex_screen.dart`) — bunlar farklı bir görsel dil taşıyabilir,
  Casper onayı olmadan dokunulmaz.

## 5. Doğrula

- `flutter analyze` — sıfır hata/uyarı.
- `flutter test` — tamamı geçmeli, kaç test kaçtı raporda yaz.
- Dokunduğun her ekranın öncesi/sonrası görüntüsü:
  `docs/ui-faz2-goruntuler/oncesi-<ekran>.png` /
  `sonrasi-<ekran>.png` (Faz 1'deki klasör deseniyle aynı).

## 6. Nasıl rapor ver

Faz 1'deki format aynen geçerli — kanıtla, anlatma:
- `flutter analyze` çıktısının tamamı
- `flutter test` çıktısının son 20 satırı
- Değiştirdiğin/eklediğin dosyaların listesi
- Rapordaki bir değerden saptıysan, hangi değeri neden seçtiğini yaz
- Bir yerde ortak bileşene sığmayan özel durum varsa dokunma, ayrı başlıkta bildir

**Uydurma yasak.** Çalıştırmadığın komutun çıktısını yazma. Yarım işi
tam gibi gösterme — "yapılamadı, şu yüzden" demek yarım bırakmaktan iyidir.

## 7. Takılırsan

- `AppScreenScaffold`'un imzasına bakmak için doğrudan
  `lib/widgets/common/app_screen_scaffold.dart`'ı oku — kendi yazdığın kod.
- Bir ekranda hem `bgEditor` hem `surface` bilinçli kullanılmış olabilir
  (ör. bir alt kart farklı vurgu için); rapor bunu söylemiyorsa ve emin
  değilsen değiştirme, raporda ayrı başlık altında sor.
