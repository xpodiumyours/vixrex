# VixRex — Bağlam (Vault kök notu)

> Bu dosya bir **hub/index not**. Uzun bir sohbet raydan çıktığında veya yeni
> bir model/oturum işe başlarken, önce bunu, sonra aşağıdaki `[[wikilink]]`
> ile işaretli notları okuyarak dakikalar içinde bağlam kazanır — 100
> mesajlık geçmişi yeniden anlatmaya gerek kalmaz.
>
> **ÖNCE OKU — Casper ile çalışma notu:** [[casper-calisma-notu-2026-08-17]]
> (kullanıcıyı tanıma + sohbetten kopmadan devam etme — her oturum başında okunur,
> her oturum sonunda güncellenir; dosya şişirilmez, yalnız değişen yerler tazelenir).

## Vault kuralı (2026-08-15, kullanıcı kararı)

**Kod/runtime = mevcut teknik gerçek. Bu dosya + `docs/adr/` = onaylanmış
hedefler ve kararlar.**

Çelişki çıkarsa **kod kazanır** — Vault (bu dosya, ADR'ler) yanlış/eski
kalmışsa güncellenir, kod ona uydurulmaz. Gerekçesi: [[0003-vault-baglam-kurali]].

## VixRex nedir (onaylanmış hedef)

Esnafın **kod bilmeden, tek tıkla** dijital vitrin sahibi olmasını sağlayan platform. Felsefe: "esnaf yazıya tıklar, VixRex Asistan değiştirir".

İki istemci:
- **Flutter** (`lib/`) — esnaf paneli: kurulum, vitrin edit, ürün, randevu, Instagram
- **Next.js** (`public_web/`) — public vitrin `/v/:slug` + sahip tıkla-düzenle paneli

İkisi de aynı Supabase'e yazar. Tek omurga kararı: [[0001-vixrex-core-omurga-ve-uzman-beyinler]].

## Hızlı başlangıç (30 saniye)

1. `AGENTS.md` → nasıl çalışılır, skill ve PR kuralları
2. `VIXREX_RULES.md` → ürün/güvenlik/kanıt sınırları
3. Bu dosya → şu anki gerçek ne
4. `docs/agents/repository-guide.md` → depo haritası ve komutlar

Kodla çelişirse **kod kazanır**, sonra bu dosya düzeltilir.

## Şu anki gerçek (2026-08-30 doğrulanmış — kod kazanır)

> **GÜVENLİ GERİ DÖNÜŞ:** `main @ 455d846` (chore: yeni GA). Önceki güvenli nokta `e160f71` (premium öncesi) artık geride — premium 6 migration main'de.

**Canlıda ne var (kod + migration + testten doğrulandı):**
- **Premium/Kiralık:** 6 migration main'de (`20260817_premium_*` + `20260820_iade` + `20260821_expiry`). Kirala → 14 gün deneme → aylık 299 TL. Kod `supabase/migrations/` ile uyumlu, canlı `premium_orders` RLS fail-closed.
- **Vitrin görünümü (29 Ağustos, 5 PR merge `c98e2b8`):** hero kapak metni kapatmıyor, üst çubuk sayfa başında gizli, tek eylem WhatsApp, mobil kartlar kesilmiyor. Test `vitrin: bolum kosullarini gercek cizim yerinden olc` kilitliyor.
- **Keşfet eşitliği (bu oturum, doğrulanmış):** Flutter `lib/screens/explore_screen.dart:303` arama + template grup + favori + pin + WhatsApp sheet → Next `public_web/src/components/kesfet/KesfetIcerik.tsx:1` ve `VitrinKarti.tsx:12` ile akış+görünüm eşitlendi. SEO `revalidate 300` + `generateStaticParams` 19 kategori korunarak (client filtre, SSR bozulmadı). `npm run test 113/790 PASS`, `npm run build ○ /kesfet SSG`.
- **Asistan tek kaynak:** `shared/vixrex_mesajlar.json` (99 mesaj) + `shared/vitrin_alanlari.json` + `vitrinFieldSchema.ts` → `schema-drift` CI kilitli. Landing asistanı hibrit: taslak `sessionStorage vixrex_asistan_taslak` + gerçek `POST /api/create-store` (`LandingAsistanSohbeti.tsx:168` `yayinla()`). Yorum satırı `landingAsistanAkisi.ts:20` güncellendi.
- **Instagram:** Kapalı `lib/config/instagram_sync_config.dart:enabled=false` (default). Kod hazır, Meta Review bekliyor.
- **Güvenlik:** rent-demo HMAC, RLS, CSP `next.config.ts:41` allowlist, `vercel.json:44` Flutter noindex — hepsi main'de.

**Açık işler (GitHub Issues'ta, burada değil):** `docs/durum.md` ve `Vault/Vixrex Açık İşler.md` — 18 issue, hepsi geçerli (tek ürün kararı #328 bekliyor). Bu dosya issue listelemez.

## Kalıcı kararlar (ADR'ler)

- [[0001-vixrex-core-omurga-ve-uzman-beyinler]]
- [[0002-vixrex-asistan-rehberli-tamamlama]] — kural-tabanlı, LLM değil
- [[0003-vault-baglam-kurali]]

## Diğer kaynaklar (tamamlar, yerine geçmez)

- `AGENTS.md`, `VIXREX_RULES.md`
- `docs/agents/repository-guide.md`, `docs/agents/store-editor-controller-parcalama.md`
- `docs/vitrin-alan-semasi.md` (canonical: `vitrinFieldSchema.ts`)
- `docs/durum.md`, `docs/arsiv/` (biten işler)
- `docs/adr/` (0001-0003)
