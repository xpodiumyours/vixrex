# deepseek görevi — manuel panele eksik 12 alanı ekle (Tek Asistan Planı, yarım kalan Aşama 1)

Bu dosyanın tamamı tek seferde deepseek'e yapıştırılacak prompt'tur.
Aşağıdaki çizginin altındaki her şey kopyalanır.

---

Sen VixRex deposunda çalışıyorsun: `C:\Projects\vixrex`.

## 1. Bağlam

6 Ağustos'ta `docs/tek-asistan-plani.md` Aşama 1 yapıldı: vitrinin 44
alanının tek tanımı `public_web/src/lib/vitrinFieldSchema.ts`'te,
oradan üretilen `lib/config/vitrin_alanlari.g.dart` Flutter'a besleniyor.

**Ama bu yalnız kurulum sohbetine (`vixrex_onboarding_chat_screen.dart`,
`vixrex_profile_snapshot.dart`) bağlandı.** Esnafın normal düzenleme
ekranı — **manuel form paneli** (`lib/screens/my_vitrin/sections/
vitrin_form_section.dart` ve altındaki editör kutuları) — hiç
bağlanmadı. O ekran hâlâ kendi eski, elle yazılmış alan setini
kullanıyor (bkz. `lib/services/store_publish_payload_builder.dart`).

**Sonuç:** 12 alan esnafın gördüğü hiçbir yerden doldurulamıyor —
ne sohbet dışında bir kutu var, ne kaydediliyor.

## 2. Eksik 12 alan ve doğal yuvaları

| Alan (şema anahtarı) | Kolon | Ne işe yarıyor | Nereye eklenmeli |
|---|---|---|---|
| `heroLocationText` | `hero_location_text` | Hero altı kısa konum yazısı | `lib/widgets/editor/location_editor_section.dart` |
| `haritaEtiketi` (`mapLabel`) | `map_label` | Harita kartı adres etiketi | Aynı dosya, konum bölümü |
| `kategoriBolumBaslik` | `category_section_title` | Kategori bölümü başlığı | Ürün/kategori yönetimi ekranı — `vitrin_form_section.dart` içindeki "Ürünlerimi Yönet" civarı, ya da yeni bir alan grubu |
| `urunBolumBaslik` | `product_section_title` | Ürün bölümü başlığı | Aynı yer |
| `galeriAksiyonMetni` | `gallery_action_label` | Galeri buton metni | `lib/widgets/editor/gallery_editor_section.dart` |
| `galeriAksiyonLinki` | `gallery_action_href` | Galeri buton linki | Aynı dosya |
| `blogUstBaslik` | `blog_section_kicker` | Blog bölümü üst başlık | `lib/widgets/editor/blog_seo_panel.dart` |
| `blogBaslik` | `blog_section_title` | Blog bölümü başlığı | Aynı dosya |
| `sssUstBaslik` | `faq_section_kicker` | SSS bölümü üst başlık | `lib/widgets/editor/faq_editor_sheet.dart` |
| `sssBaslik` | `faq_section_title` | SSS bölümü başlığı | Aynı dosya |
| `sssAciklama` | `faq_section_description` | SSS bölümü açıklaması | Aynı dosya |
| `bolumGorunurluk` | `section_visibility` | 7 bölümü aç/kapat (categories/products/about/gallery/blog/faq/contact) | Yeni, küçük bir ayar bloğu — bkz. madde 4 |

Tam tanımlarına (tip, karakter sınırı, açıklama) `lib/config/
vitrin_alanlari.g.dart` içinden `anahtar` ile bak — kolon adları,
etiketler ve `ipucu` metinleri zaten orada, uydurma.

## 3. Kesin kural — yalnız UI eklemek yetmez, üç katman var

Geçmişte tam bu şekilde bir hata oldu (bkz. `git log` — "Hakkımızda ve
SSS ilk yayında da kaydediliyor" düzeltmesi, 2026-08-08): alan formda
görünüyordu ama kaydetme yolunda unutulmuştu, esnaf dolduruyordu, veri
sessizce kayboluyordu. **Bu üç katmanın hepsi eksiksiz olmalı, biri
eksikse iş yarım demektir:**

1. **Model** — `lib/models/store_data.dart` ve `store_data_dto.dart`'a
   bu 12 alanı ekle (camelCase, mevcut alanlarla aynı desende).
2. **Kayıt yolu** — `lib/services/store_publish_payload_builder.dart`
   içindeki `toStoreUpdateMap`'e bu 12 kolonu ekle (snake_case kolon
   adlarıyla, mevcut satırlarla aynı desende — `.trim()` unutma).
3. **Form (UI)** — yukarıdaki tabloya göre input kutularını ekle,
   mevcut `EditorTextField`/`EditorDropdownField`
   (`lib/widgets/editor/common_form_fields.dart`) bileşenlerini
   kullan, yeni bir stil icat etme.

`section_visibility` farklı: metin değil, 7 açık/kapalı anahtarı olan
bir JSONB. Aşağıya bak.

## 4. `section_visibility` — ayrı ele al

Bu bir metin kutusu değil. Esnafın "bu bölümü gizle" diyebileceği 7
anahtarlı basit bir ayar bloğu gerekiyor: `categories`, `products`,
`about`, `gallery`, `blog`, `faq`, `contact` — her biri bir `Switch`/
toggle, açıklaması "Boş bırakılırsa veri doluysa otomatik görünür."

Yeni bir dosya aç: `lib/widgets/editor/section_visibility_card.dart`
— 7 satırlık basit bir kart, mevcut kart deseniyle (var olan editör
kutularının görünümüne bak, aynı `AppColors` kullan). `vitrin_form_
section.dart`'a uygun bir yere ekle (öneri: en altta, "Gelişmiş
Ayarlar" gibi ayrı bir bölüm — zorunlu değil, karışıklık yaratmasın).

Veri şekli: `Map<String, bool>`, yalnız kapatılan anahtarlar
gönderilir ya da hepsi gönderilip boş obje varsayılan kabul edilir —
`section_visibility` sütununun mevcut davranışına bak
(`supabase/migrations/20260804220000_add_owner_editable_section_labels.sql`
içindeki açıklamaya).

## 5. Kesin kurallar

1. Yalnız `lib/` altına dokun (bu görev tamamen Flutter tarafı;
   Next.js şeması zaten hazır, ona dokunmuyorsun).
2. Şemadaki `anahtar` değerlerini değiştirme, yalnız oku.
3. Mevcut alanların kayıt/görüntüleme davranışını bozma.
4. Türkçe yaz, depo kuralına uy.
5. Alanların hepsi **isteğe bağlı** (zorunlu değil) — boş bırakılabilir,
   boşsa hiçbir hata vermemeli.

## 6. Doğrula — üç katman da test edilecek

1. `flutter analyze`, `flutter test` (tam paket) temiz.
2. **Kayıt round-trip'i elle veya testle kanıtla:** bir alanı doldur →
   kaydet/yayınla → ekranı kapat/aç (ya da veritabanından oku) → değer
   hâlâ orada mı? Bu görevin en kritik doğrulaması — yalnız ekranda
   görünmesi yetmez, gerçekten kaydedildiğini göster.
3. Ekran görüntüsü: dolu ve boş durum, formun bozulmadığını göster.
4. `section_visibility` için: bir bölümü kapat → yayınla → vitrin
   sayfasında (Next.js tarafı zaten `section_visibility`'i okuyor,
   `public_web/src/app/v/[slug]/page.tsx`'e bak) o bölüm gerçekten
   kayboluyor mu kontrol et — bu iki tarafın (Flutter yazma, Next.js
   okuma) gerçekten uyuştuğunu kanıtlar.

## 7. Dal

`duzeltme/manuel-panel-eksik-alanlar` main'den (ayrı worktree hazır:
`C:\Projects\vixrex-manuel-panel-worktree`).

## 8. Nasıl rapor ver

Kanıtla, anlatma. Üç katmanın (model/kayıt/form) hepsinin değiştiğini
diff ile göster — yalnız form değiştiyse iş yarımdır, öyle rapor et.
Round-trip kanıtı olmadan "kaydediliyor" deme. Uydurma yasak.
