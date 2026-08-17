# VixRex — Bağlam (Vault kök notu)

> Bu dosya bir **hub/index not**. Uzun bir sohbet raydan çıktığında veya yeni
> bir model/oturum işe başlarken, önce bunu, sonra aşağıdaki `[[wikilink]]`
> ile işaretli notları okuyarak dakikalar içinde bağlam kazanır — 100
> mesajlık geçmişi yeniden anlatmaya gerek kalmaz.

## Vault kuralı (2026-08-15, kullanıcı kararı)

**Kod/runtime = mevcut teknik gerçek. Bu dosya + `docs/adr/` = onaylanmış
hedefler ve kararlar.**

Çelişki çıkarsa **kod kazanır** — Vault (bu dosya, ADR'ler) yanlış/eski
kalmışsa güncellenir, kod ona uydurulmaz. Sebep: kod her zaman çalışan,
doğrulanabilir gerçek; bir not eskiyip unutulabilir ama kimse fark etmez.
Gerekçesi: [[0003-vault-baglam-kurali]].

**Pratik sonuç:** Bir iddia burada veya bir ADR'de yazıyor ama kodda
doğrulanamıyorsa (ör. bir dosya/fonksiyon artık yok, davranış değişmiş) —
önce kodu doğru kabul et, sonra bu notu düzelt. Tersini yapma.

## VixRex nedir (onaylanmış hedef)

Esnafın (küçük işletme sahibi) **kod bilmeden, tek tıkla** dijital vitrin
sahibi olmasını sağlayan platform. Merkezi felsefe: "esnaf yazıya tıklar,
VixRex Asistan değiştirir" — form doldurtmak değil, sohbet/tıkla-değiştir
deneyimi.

İki istemci:
- **Flutter** (`lib/`) — esnafın kendi paneli: sahiplik, vitrin kurulumu,
  ürün/kategori yönetimi, randevu, Instagram senkronu.
- **Next.js** (`public_web/`) — herkese açık vitrin sayfaları (`/v/:slug`)
  + sahip modunda "Vixrex Asistan" tıkla-değiştir paneli.

İkisi de aynı Supabase/Postgres çekirdeğine yazar. Hangi mantığın **tek
omurgada** (backend/DB) hangisinin **istemciye özel** kalacağı bilinçli bir
karar: [[0001-vixrex-core-omurga-ve-uzman-beyinler]].

## Şu anki teknik/ürün durumu (2026-08-17 itibariyle — bu bölüm en hızlı
eskiyen kısım, kod ile çelişirse KOD kazanır)

- **CSP/görseller (2026-08-17):** #193'ün `img-src *` → allowlist dönüşümü
  vitrinlerin gerçekte kullandığı hostları (images.unsplash.com, api.qrserver.com)
  ve maps.google.com'u (frame-src) listeye eklememişti — görseller sessizce
  engelleniyordu. PR #197 ile eklendi + kontrat testi ve E2E görsel yükleme
  testi (canlı tarayıcı, main push'ta) eklendi. Font kırılmasıyla (#196) aynı
  desendi: CSP daraltılırken gerçek kaynaklar taranmadan liste kesilmişti.
- **CI onarımı (2026-08-17):** ci.yml #189'dan beri HİÇ çalışmıyordu — step-level
  `if` içinde `secrets` context'i kullanımı workflow'u GitHub'da geçersiz
  kılıyordu (0s "invalid workflow" fail). Düzeltildi (PR #197); Flutter/Next.js
  testleri, gitleaks ve auth check yeniden CI'da koşuyor. Ders: PR check
  listesinde ci.yml job'ları görünmüyorsa workflow geçersizdir, sessizce
  "yeşil" gibi görünür.
- **Güvenlik:** rent-demo klon RPC'si, audit-log yetkileri, varsayılan
  fonksiyon izinleri, upload/report oran sınırları güvenlik taramasıyla
  kapatıldı (PR #183-188, main'de). CSP/Sentry/CI güvenlik kontrolü ayrı
  bir oturumda (Kilo CLI) paralel işleniyor — bu dosya o işin bittiğini
  VARSAYMAZ, kodda doğrula.
- **Instagram ürün içe aktarma:** kod tam (Meta OAuth ile bağlanma, medya
  seçme, ürüne aktarma) ama **`INSTAGRAM_SYNC_ENABLED=false`** —
  `lib/config/instagram_sync_config.dart`. Meta App Review'a henüz
  başvurulmadı (2026-08-15 itibariyle). Bilinen eksikler: sayfalama yok
  (yalnız ilk ~25 medya), toplu seçim yok (tek tek), video/reels
  desteklenmiyor (yalnız fotoğraf). Araştırma:
  `docs/research/vixrex-google-urun-yerel-seo-2026-08-15.md`.
- **Vixrex Asistan rehberli tamamlama:** [[0002-vixrex-asistan-rehberli-tamamlama]]
  kararına göre kural-tabanlı (gerçek LLM çağrısı yok) — bilinçli, maliyet/
  tutarlılık gerekçesiyle.
- **Tek Asistan Planı tamamlandı (2026-08-17):** üç aşama da koda girdi —
  tek mesaj katalogu (`shared/vixrex_mesajlar.json`), tek şema
  (`shared/vitrin_alanlari.json`), tek "sırada ne var" motoru (iki istemci de
  şemadaki `zorunlu` işaretinden karar verir). CI `schema-drift` sapma
  kontrolünde. Detay: `docs/tek-asistan-plani.md`.

## Kalıcı kararlar (ADR'ler)

- [[0001-vixrex-core-omurga-ve-uzman-beyinler]] — hangi mantık tek omurgada, hangisi istemciye özel.
- [[0002-vixrex-asistan-rehberli-tamamlama]] — rehberlik motoru neden kural-tabanlı, LLM değil.
- [[0003-vault-baglam-kurali]] — bu dosyanın kendisinin var oluş gerekçesi.

## Diğer kaynaklar (bu dosyanın YERİNE geçmez, tamamlar)

- `AGENTS.md` — ajan başlangıç sırası, yetki sınırları, skill akışı.
- `VIXREX_RULES.md` — ürün/güvenlik/kanıt/canlı sistem sınırları (operasyonel kurallar).
- `docs/agents/repository-guide.md` — teknik depo haritası.
