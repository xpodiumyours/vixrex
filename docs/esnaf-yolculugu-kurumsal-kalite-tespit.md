# Esnaf yolculuğu — kurumsal kalite tespiti

Tarih: 2026-10-27. Ölçüm: canlı vixrex.com (commit `8c162aa7`), DENEME 5 vitrini
(`v/deneme-5-mvps6i4j`, GİYİM / Ümraniye), esnaf hesabıyla gerçek ekranlar gezilerek.
Bu bir ölçüm raporudur, plan değildir. Bilinmeyenler "ölçülmedi" diye yazılıdır.

## Yolculuk haritası (adım → durum)

| Adım | Durum | Not |
|---|---|---|
| Vitrin oluşturma | Çalışıyor | DENEME 5 canlı, taslak durumunda |
| Vitrin özelleştirme (editör + Asistan) | Çalışıyor ama tıkanıklı | 8/46 alan dolu, %17 hazır, Aşama 1/3 (bkz. T2, K6) |
| Ürün yönetimi | Çalışıyor | Boş durum temiz; 5 ayrı ekleme yolu var (bkz. T4) |
| Fatura → ürün kartı | Yükleme sonrası ekranlar ölçülmedi | Zincir kodda canlı; DENEME 5'te canlı koşu henüz yapılmadı (bkz. F1) |
| Müşteri görünümü | Kısmen | Hero + iletişim + harita var; tüm bölümler boş (bkz. T2) |

## Tıkanıklıklar (akışta durduran / kafayı karıştıran)

- **T1 — Taslak ile canlı sürüm uyuşmazlığı.** Editörde turuncu bant:
  "Canlı vitrin değişmiş — burada gördüğün eski hâli" + elle "Canlı sürümü al" düğmesi.
  Esnaf hangi hâlin gerçek olduğunu bilmiyor; senkron elle yapılıyor.
- **T2 — Vitrin kurulurken dışarıya boş görünüyor.** 46 alanın 8'i dolu; tüm bölümler
  "müşteriye görünmüyor" etiketli. Esnaf emek verirken vitrininin hiçbir şey
  göstermediğini görüyor; hazır olma hissi yok. (Müşteri tarafında hero + adres +
  WhatsApp + harita dışında bölüm yok.)
- **T3 — Fatura akışında beklenti yönetimi yok.** Tek cümle var: "Fotoğrafı yükle.
  Kartlar hazırlanır. Satış fiyatını yazıp yayınlarsın." İşlem süresi (araştırma
  adımı uzun) ve maliyet önceden söylenmiyor; akış içi ekranlar ancak yüklemeden
  sonra görülüyor. Para sayacı / süre bütçesi göstergesi zaten yok (TAKIP #6).
- **T4 — Ürün ekranında 5 giriş yolu, yönlendirme yok.** "Fatura fotoğrafını yükle",
  "Vixrex önerileri", "+ Yeni Ürün Ekle", "Toplu Ürün Yükle", "XML ile Yükle".
  Hangisinin ne zaman kullanılacağını anlatan bir sıra/kılavuz yok ("Vixrex önerileri"
  ne yapıyor — ölçülmedi).

## Kurumsallık dışı MVP parçaları

- **K1 — Yeni vitrinde "4.9 (128 değerlendirme)" görünüyor.** Sıfır ürünlü, yeni
  açılmış vitrinde bu puan inandırıcı değil. Kaynağı doğrulanmalı (yerleşik demo
  verisi mi?): değerlendirme yokken puan gizlenmeli ya da kaynak açıkça etiketlenmeli.
  Uydurma değerlendirme, uydurma ürün sayfası kadar kanıt kuralına aykırıdır.
- **K2 — Adres tutarsızlığına uyarı yok.** İlçe "Ümraniye" ama adres metni
  "ÇEKMEKÖY ÇATAL MEŞE NO 2". Serbest metin girişinde tutarlılık denetimi yok.
- **K3 — Durum dili dağınık.** Aynı gerçek üç yerde üç dille: üstte "Taslak önizleme
  — bu vitrin henüz yayında değil, müşteriler göremez", hero'da kırmızı "ŞU AN KAPALI",
  editörde "Canlı vitrin değişmiş" bandı. Tek bir durum cümlesi olmalı.
- **K4 — Keşfet kartında "Kapak görseli eklenmedi"** placeholder'ı ile listeleniyor.
  Kapaksız vitrinin keşfet sıralamasında/görünürlüğünde kural yok.
- **K5 — Alan adları geliştirici dili.** "Harita Kartı Etiketi", "Konum — Enlem",
  "Konum — Boylam", "Görsel Alt Yazısı", "Referanslar Bağlantısı". Esnaf bu adlardan
  ne anlamalı? 46 alanın dili esnaf Türkçesine çevrilmeden "kurumsal" olmaz.
- **K6 — Fatura akışında maliyet/süre/iptal şeffaflığı yok** (T3 ile aynı kök).
  Yayınlama kapısı ise doğru kurulmuş: kanıt + satış fiyatı + stok onayı + en az
  1 fotoğraf + esnaf onayı beşli kapı; taslaklar müşteriye görünmez.

## Fatura fotoğrafı → ürün kartı (özel durum)

- Zincir canlıda sağlam: okuma (Luna) → satır izolasyonu (tek satır faturayı düşürmez)
  → varyant/beden ayrımı → şema köprüsü → görsel köprüsü (gerçek açılan resmî sayfanın
  fotoğrafı) → görünmez taslak → 5 şartlı yayın kapısı. Hepsi PR #698–#699 ile canlıda.
- **Açık kanıt: F1 — DENEME 5'te canlı koşu yapılmadı** (0 ürün). Test faturaları hazır;
  yükleme sonrası ekranlar (bekleme ekranı → kart listesi → fiyat/onay → yayın) bu
  koşuyla ölçülecek. Beklenen dürüst durumlar: "Doğrulandı / Belirsiz / Bulunamadı"
  kartları, fiyat uydurmama, fotoğraflar yalnız açılan resmî sayfadan.
- Eski ölçümden bilinen risk: kimi fişlerde tedarikçi adı boş okunuyor (satış fişi);
  bu durum kart üretimini "Belirsiz/Bulunamadı" ile dürüst karşılıyor.

## Önerilen sıra (onayına açık)

1. **Canlı fatura koşusu** (test faturanla) — akışın kalan ekranlarını da ancak böyle
   görürüz; kurumsal kalite işinin verisi buradan çıkar.
2. **T1 + K3** aynı problem ailesi: "hangi hâl gerçek" — tek durum dilli, otomatik
   senkronlu editör.
3. **K1 + K2 + K4** küçük işler, kurumsal etkisi büyük (dürüstlük + tutarlılık).
4. **T2 + T3 + K5** asıl "donanımlı kurumsal kalite" dönüşümü: beklenti yönetimi,
   esnaf dili, adım kılavuzu.
5. **TAKIP #6** para sayacı ve süre bütçesi (T3'ün kalıcı çözümü).

## Karar bekleyenler (Casper'a ait)

- K1: vitrindeki "4.9 (128 değerlendirme)" nereden geliyor — demo verisi ise kaldırılsın
  mı, gerçek Google puanı gibi mi bağlansın?
- K5: alan adlarının esnaf Türkçesine çevrilmesi kapsamlı bir iş; yapılsın mı?
- T4: "Vixrex önerileri" ve "XML ile Yükle" yolları sadeleştirilsin mi?

## Bağlantılı kayıtlar

- TAKIP.md — iş listesi (fatura işleri #13–#17 BİTTİ; #6 ve #7 BEKLİYOR)
- docs/URUN-EKLE-FATURA-DURUM.md — fatura zincirinin 2026-10-04 ölçümü (katalog havuzu
  satırları geçersiz, kural 20)
- Yerelde bekleyen: #11 kırmızı test düzeltmesi commit edilmedi (bu tespitten bağımsız)
