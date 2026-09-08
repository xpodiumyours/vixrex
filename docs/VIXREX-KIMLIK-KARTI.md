# Vixrex — Kimlik Kartı (Düz Türkçe Özet)

> **Bu dosya nedir:** Casper'a (proje sahibine) projeyi tekrar anlatmamak için yazıldı.
> **Bu dosyayı okuyan her ajan/kod yazıcısı:** Projeye dokunmadan ÖNCE bu dosyayı oku ve aşağıdaki kurallara uy.
> **Tarih:** 2026-09-08

---

## 1. Bu proje tek bir uygulama değil, aynı depoyu paylaşan 2 ayrı site

| Adres | Ne işe yarar | Kim kullanır | Güncel durum |
|---|---|---|---|
| **`vixrex-app.vercel.app`** | İşletme sahibinin **panel/arka ofis** uygulaması (vitrin düzenleme, ürün, asistan). **Flutter web hali.** | İşletme sahibi | ✅ **ÇALIŞIYOR — EN İYİ/EN KİLİTLİ YER** |
| **`www.vixrex.com`** | Müşteriye görünen **vitrin/tanıtım** sitesi (Keşfet, vitrin sayfaları, asistan). **Next.js hali.** | Müşteriler | ✅ **ÇALIŞIYOR** |

İkisi de **aynı veritabanını (Supabase)** kullanır; birinin yayınlanması diğerinin de yayına hazır olduğu anlamına **gelmez** — ayrı ayrı doğrulanır.

> Benzetme: **Flutter panel = mağazanın arka ofisi (kasa)** · **Next.js site = mağazanın önü (vitrin)**.

---

## 2. Kodda bu ikisi nerede durur

| Klasör | Ait olduğu site | Teknoloji |
|---|---|---|
| `lib/` | Flutter panel (`vixrex-app`) | Flutter (Web + Android) |
| `public_web/` | Next.js site (`www.vixrex.com`) | Next.js (TypeScript) |
| `shared/` | İkisinin **ortak tek kaynağı** (şemalar) | JSON |
| `supabase/` | Veritabanı (Supabase/PostgreSQL) | SQL |

---

## 3. EN ÖNEMLİ KURALLAR (her ajan burayı ihlal etme)

1. **`vixrex-app.vercel.app` (Flutter panel) en iyi çalışan yerdir.** Casper defalarca
   "buraya dokunmayın" dedi. Burayı **var sayılan (referans/kilit) gözle gör** ve
   **izinsiz değiştirme**.
2. **"Flutter değişmez, Next.js hizalanır" kuralı vardır.** Bir görünüm farkı çıkarsa
   Flutter doğru kabul edilir; düzeltme **Next.js tarafında** yapılır, Flutter'da değil.
3. **Tasarım renkleri bilinçli ayrıdır:** Yönetim paneli/lansman `#147DFF` (elektrik
   mavisi) ailesini, canlı vitrin sayfaları `#38A0E4` ailesini kullanır. Bu **bilinçli bir
   karardır, hata sayılmaz, "düzelteyim" diye birleştirilmez.**
4. **Ana sayfadaki asistan sohbeti bir makettir.** Gerçek değildir, motora bağlanmaz.
5. **Canlı şema yalnız `supabase/migrations/` ile değişir.** Dashboard'dan elle değiştirilmez.
6. **Hiçbir değişikliği Casper'a sormadan yapma — küçük görünse bile.** Onay almadan
   ana koda (main) dokunma; önce sor, cevabı bekle.

---

## 4. Gelişme hikayesi (kısa)

1. Başta mobil uygulama istendi → Flutter ile **mobil + web** aynı koddan çıktı.
2. "Web'de de olsun" denildi → Flutter'ın web hali `vixrex-app` doğdu (en sevilen yer).
3. "Google'da aranmak için Next.js gerek" öğrenildi → `www.vixrex.com` Next.js ile yapıldı.
4. İkisi de canlı, ikisi de çalışıyor, gerçek kullanıcı henüz yok.

---

## 5. Yol haritası (sadece Casper karar verir)

- Bekleyen "parite" (eşleme) işleri, web'i mabile eşitlemekle ilgilidir (#437, 438, 439, 436).
- Bunlar **henüz ana koda alınmamış** "bekleyen iş paketleridir".
- APK (Android) ayrıca geridedir ve **canlı iki siteyi etkilemez**; ona ayrı bir günde bakılır.
- **Öncelik sırası:** Sağlam çalışan yapıyı bozmamak → sonra eşitleme → sonra APK.

---

_Not: Bu dosya Casper'ın kafasındaki hikâyeyi yazıya döker; kod hakkında yeni kural üretmez._