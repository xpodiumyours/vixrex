# deepseek görevi — sahte tema seçiciyi kaldır

Bu dosyanın tamamı tek seferde deepseek'e yapıştırılacak prompt'tur.
Aşağıdaki çizginin altındaki her şey kopyalanır.

---

Sen VixRex deposunda çalışıyorsun: `C:\Projects\vixrex`.

## 1. Sorun (ölçüldü, doğrulandı)

Hem Flutter'ın manuel panelinde (`store_theme_picker.dart`, "Sade"/"Premium"
seçeneği) hem Next.js sahip panelinin şemasında (`vitrinFieldSchema.ts`,
"Tema Ön Ayarı" alanı) bir tema seçici var. İkisi de sahibe "bunu
değiştirebilirsin" izlenimi veriyor. **Ama hiçbiri işe yaramıyor:**

- Flutter `theme` sütununa yazıyor.
- Next.js şeması `theme_preset` sütununa yazıyor.
- Vitrini çizen kod (`public_web/src/app/v/[slug]/VitrinProfileView.tsx`
  ve altındaki her bileşen) **ikisine de hiç bakmıyor** — grep ile
  doğrulandı, sıfır eşleşme.

Yani esnaf tema değiştiriyor sanıyor, vitrin hiç değişmiyor. **Karar
(Casper, 2026-08-08): tema özelliği istenmiyor.** Gerçek özellik hâline
getirilmeyecek — seçici kaldırılacak.

## 2. Görevin — yalnız görünürdeki seçiciyi kaldır

**Küçük ve dar tutulmalı.** Veritabanı sütunlarını (`theme`,
`theme_preset`) veya `StoreData` modelindeki alanı **silme** — ölü
kalsınlar, zararsızlar. Yalnız kullanıcının gördüğü, yanıltan kısmı kaldır:

### A. Flutter

- `lib/screens/my_vitrin/sections/vitrin_form_section.dart` içinde
  `StoreThemePicker` kullanımını kaldır (ilgili import dahil).
- `lib/widgets/editor/store_theme_picker.dart` dosyasını sil.
- Kaldırınca derleme hatası çıkarsa (kullanılmayan değişken, boş
  bırakılan bir Column child vb.) düzelt.

### B. Next.js

- `public_web/src/lib/vitrinFieldSchema.ts` içindeki `anahtar: "tema"`
  girdisini (satır ~142-149) kaldır.
- `public_web/tests/vitrin-field-schema.test.ts` içinde alan sayısına
  bağlı bir doğrulama varsa (ör. "41 alan" veya "44 alan" gibi sabit bir
  sayı bekliyorsa) güncelle — şemadan bir alan azaldı.
- `docs/vitrin-alan-semasi.md` bölüm 5.1'deki `tema` satırını kaldır
  ve altındaki not/liste sayısını güncelle (bu dosya insan tarafı
  belge, kodu değiştirmez ama tutarsız kalmasın).

## 3. Kesin kurallar

1. Veritabanı migration'ı yazma — sütun silmiyoruz, yalnız UI kaldırıyoruz.
2. `StoreData` modelindeki `theme`/`themePreset` alanlarını, DTO'ları
   (`store_data_dto.dart`) değiştirme — geniş bir refactor değil bu.
3. Türkçe yaz, depo kuralına uy.
4. Landing, vitrin render'ı (`public_web`'in müşteri tarafı dışında kalan
   kısmı), `vitrin_theme_preset.dart` (Flutter — ayrı bir şey, QR kodu
   renkleri için kullanılıyor olabilir, **buna dokunma**, sadece seçici
   widget'ı kaldırıyorsun) — hiçbiri bu görevin kapsamında değil.

## 4. Doğrula

- `flutter analyze` — sıfır hata.
- `flutter test` — tamamı geçmeli.
- Next.js: `npm run lint` ve `npm run build` (veya `npx tsc --noEmit`)
  `public_web` içinde temiz kalmalı.
- Manuel panelde tema seçme kutusunun artık görünmediğini, ekranın
  bozulmadığını (boşluk/hizalama kaymadığını) ekran görüntüsüyle göster.

## 5. Nasıl rapor ver

Aynı kural: kanıtla, anlatma. Komut çıktıları, değişen dosya listesi,
öncesi/sonrası ekran görüntüsü. Uydurma yasak.
