# Ürün Kartları & Gösterim İyileştirme Listesi

Kaynak: `vitrin_product_card.dart`, `public_product_screen.dart`, `bulk_product_upload_service.dart`, `image_optimization_service.dart`

---

## Faz 1 — Hızlı Kazanımlar (Düşük Risk, Yüksek Etki)

- [ ] **Görsel önbelleği:** `Image.network` → `cached_network_image` paketi ile değiştir. Her açılışta yeniden indirme durur, uygulama anlık hızlanır.
- [ ] **AppBar ürün adı:** `PublicProductScreen` AppBar'ında "Ürün Detayı" yerine `product.name` göster.
- [ ] **Yeşil rozet kaldır / düzelt:** Katalog kartındaki yeşil checkmark rozeti "seçildi" izlenimi veriyor. Daha net bir stok göstergesi kullan veya kaldır.
- [ ] **`stockStatus` enum'a çevir:** `'Mevcut'` / `'Tükendi'` / `'Son birkaç adet'` hardcoded string — `StockStatus` enum'u oluştur.

---

## Faz 2 — Performans (Orta Risk)

- [ ] **Tek ürün API endpoint'i:** `PublicProductScreen._load()` şu an tüm mağaza ürünlerini çekiyor. 1000 ürünlü mağazada yavaşlık yaratır. Supabase'de slug ile tek ürün dönen bir RPC/view ekle.
- [ ] **WebP desteği web'de:** `flutter_image_compress` web platformunda çalışmıyor. Platform kontrolü ekle, büyük görsel olduğu gibi yüklenmesin.
- [ ] **Görsel lazy-load:** `cached_network_image` + placeholder birleşimi ile görünür olmayan kartların görseli önceden indirilmesin.

---

## Faz 3 — UX Geliştirmeleri (Orta Risk)

- [ ] **Çoklu görsel — katalog kartı:** `VitrinProductCard` yalnızca `imagePath` (tek görsel) kullanıyor. Ürün modelinde `imageUrls` listesi var ama karta geçilmiyor. İlk resim gösterilmeli.
- [ ] **Loading skeleton:** `PublicProductScreen` yüklenirken sadece spinner gösteriyor. Shimmer/skeleton ile ürün kartı şekli verilsin.
- [ ] **Görsel zoom:** Detay sayfasında `InteractiveViewer` ile pinch-to-zoom eklenmeli.
- [ ] **Stok rengi — detay sayfası:** Detay sayfasındaki `_infoCard` katalog kartındaki kırmızı/turuncu/yeşil renk sistemini kullanmalı.

---

## Faz 4 — Toplu Yükleme İyileştirmeleri (Düşük Risk)

- [ ] **Dosya boyutu limiti:** `BulkProductUploadService.parse()` boyut kontrolü yapmıyor. 50.000 satır CSV belleği patlatır. Max 5 MB limiti ekle.
- [ ] **Bulk import — görsel URL sütunu:** CSV/Excel'de `Görsel URL` sütunu desteklenmiyor. `_imageUrlAliases` ekle, `imageUrls` alanına aktar.
- [ ] **ID çakışma riski:** Bulk import'ta `DateTime.now().microsecondsSinceEpoch` ID — aynı anda iki satır aynı ID'yi alabilir. `uuid` paketi ile benzersiz ID üret.

---

## Tamamlandı

_(Burası faz ilerledikçe doldurulacak)_
