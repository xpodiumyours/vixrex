# deepseek görevi — ürün yükleme ve blog yazma ekranlarının UI/UX araştırması (yalnız rapor, kod değişikliği yok)

Bu dosyanın tamamı tek seferde deepseek'e yapıştırılacak prompt'tur.
Aşağıdaki çizginin altındaki her şey kopyalanır.

---

Sen VixRex deposunda çalışıyorsun: `C:\Projects\vixrex`.

## 1. Görev — yalnız araştırma, kod değiştirme

Manuel üyelik panelinde butonla açılan şu ekranların/sayfaların,
Faz 1'de kurulan görsel tutarlılık standardına (`docs/ui-tutarlilik-envanteri.md`
ve onun uyguladığı PR #66) uyup uymadığını araştır ve
**`docs/urun-blog-ui-arastirma.md`** adında bir rapor yaz.

**Bu görevde hiçbir üretim kodu değiştirmiyorsun.** Yalnız okuyup
ölçüyorsun, rapor yazıyorsun. Düzeltme ayrı bir görev olarak (Faz 1'in
UI Faz 2'si gibi) sonra verilecek.

## 2. İncelenecek ekranlar (buton → açılan sayfa)

- **Ürün yükleme / yönetimi:**
  - `lib/widgets/product/product_management_sheet.dart`
  - `lib/widgets/product/product_editor_sheet.dart`
  - `lib/screens/bulk_product_upload_screen.dart` (toplu/XML yükleme)
  - `lib/screens/ocr_scanner_screen.dart` + `lib/widgets/ocr/ocr_scanner_widget.dart`
    (fiş/etiket fotoğrafından ürün çıkarma)
- **Blog yazısı yazma:**
  - `lib/screens/blog_editor_screen.dart`
  - `lib/widgets/editor/blog_entry_card.dart`
  - `lib/widgets/editor/blog_cover_picker.dart`
  - `lib/widgets/editor/blog_seo_panel.dart`

Bunlardan biri artık kullanılmıyorsa (ölü kod) ya da butonla hiç
açılmıyorsa bunu da raporda ayrıca belirt — varsayım yapma, gerçek
çağrı zincirini (`Navigator.push`, `showModalBottomSheet` vb.) takip
ederek doğrula.

## 3. Ölçülecek standart — Faz 1'de kurulan referans

Bugün (2026-08-08) 5 ekranda (ayarlar, bildirimler, destek, profil,
randevu yönetimi) uygulanan standart:

- `lib/theme/app_text_styles.dart` — merkezi tipografi (`AppTextStyles.*`)
- `lib/widgets/common/app_card.dart` — ortak kart (`AppCard`)
- `lib/widgets/common/app_section_header.dart` — ortak bölüm başlığı
- `lib/widgets/common/app_screen_scaffold.dart` — ortak ekran iskeleti
- `lib/main.dart`'taki `ThemeData` (`textTheme`, `appBarTheme.titleTextStyle`)

## 4. Rapor formatı — `docs/ui-tutarlilik-envanteri.md` ile aynı yöntem

Aynı ölçüm disiplinini uygula (o dosyadaki gibi komutla say, tahmin
etme):

1. **Özet tablo:** her incelenen dosya için — satır sayısı, kaç adet
   elle yazılmış `TextStyle(`, `AppTextStyles` kullanıyor mu (kaç
   yerde), `Container(decoration: BoxDecoration(...))` kart deseni
   tekrarı var mı (kaç yerde), `AppCard`/`AppSectionHeader`/
   `AppScreenScaffold` hiç kullanılıyor mu.
2. **Renk/köşe/boşluk tutarsızlığı:** bu ekranlardaki `fontSize`,
   `BorderRadius.circular(...)`, zemin rengi (`AppColors.bgEditor` vs
   `AppColors.surface` vs başka) değerlerinin dağılımı — Faz 1'in
   uyguladığı standart değerlerle (radius16, bgEditor zemin vb.)
   karşılaştır, sapmaları listele.
3. **Ekrana özgü bulgular** — bu ekranlara özel, genel UI standardının
   dışında olan ama yine de göze batan şeyler varsa (ör. yükleme
   göstergesi tutarsızlığı, buton yerleşimi, hata mesajı stili) ayrıca
   not et.
4. **Öncelik sırası önerisi** — hangi ekranın düzeltilmesi en çok fark
   yaratır (kullanım sıklığı, görsel sapma büyüklüğü), gerekçesiyle.

## 5. Kesin kurallar

1. **Hiçbir dosyayı değiştirme** — yalnız `docs/urun-blog-ui-arastirma.md`
   yeni dosyasını oluşturuyorsun.
2. Rakam uydurma — `grep -c`, `wc -l` gibi gerçek komut çıktısı kullan,
   raporda hangi komutu çalıştırdığını da yaz (önceki rapor tam bunu
   yapmıştı, doğrulandı, aynı disiplin).
3. Türkçe yaz.
4. Emin olmadığın bir çağrı zinciri varsa ("bu ekran gerçekten şuradan
   mı açılıyor") tahmin etme, kodda ara, bulamazsan raporda "doğrulanamadı"
   diye açıkça yaz.

## 6. Dal

`arastirma/urun-blog-ui-uyumu` main'den (worktree hazır:
`C:\Projects\vixrex-urun-blog-arastirma-worktree`).

## 7. Nasıl rapor ver

Raporu yaz, commit at, hangi komutları çalıştırdığını (analiz için,
kod çalıştırmak için değil) özet olarak da buraya (sohbete) yaz.
Uydurma yasak — önceki UI raporunda rakamlar tek tek doğrulanmıştı,
bu standardı düşürme.
