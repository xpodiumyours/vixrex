# Preset temizlik planı — fatura akışı (2026-10-12)

Hedef (Casper): fatura akışında OpenRouter'un sunduğu şeyleri **platformdan** almak,
kodda yeniden yazmayı bırakmak.

Kaynak: OpenRouter Presets dokümanı — https://openrouter.ai/docs/guides/features/presets
(okundu: 2026-10-12). Preset = model + system prompt + araçlar + provider kuralları
hesapta yaşar; koda gömülmez. `@preset/<slug>` ile çağrılır.

---

## A. Preset'e taşınacak — platformun işi

Tek dosya: `public_web/src/lib/faturaGoru.ts`. Ölçülen satırlar:

| Satır | Koddaki sabit | Preset karşılığı |
|---|---|---|
| 31 | `GORU_MODELI = "openai/gpt-5.6-luna"` | preset model seçimi + fallback |
| 39-96 | `SORU` sabit prompt dizisi | preset system prompt |
| 316-317 | elle kurulmuş `web_search` + `web_fetch` | preset tools |
| 427 | elle kurulmuş `web_search` | preset tools |
| 533-534 | elle kurulmuş `web_search` + `web_fetch` | preset tools |
| 486 | PDF yolunda `chat/completions` uç noktası | aynı kalır, model `@preset/` olur |
| — | provider sıralama/fallback hiç yok | preset provider kurallarıyla eklenir |

Dosyada **3 ayrı istek kalıbı** var → **3 preset**:

1. `fatura-okuma` — faturayiOku (görsel → şema)
2. `firma-arama` — firmaSitesiniModelleBul (firma sitesi bulma)
3. `satir-arama` — satirAramaIstegi (satır → ürün kanıtı)

Kodda kalan: `model: "@preset/fatura-okuma"` + satır okuma/yorumlama iş kuralları.

**Kazanç:** prompt, model ve araç değişikliği deploy gerektirmez — dashboard'dan yapılır.
Kilit kalkar: model adı koda gömülü değil, hesapta.

## B. Preset'e TAŞINMAYACAK — bunlar iş kuralı, ajan artığı değil

| Dosya | Neden platformda değil |
|---|---|
| `faturaKisiselVeri.ts` | TCKN / vergi no temizliği — KVKK, Türk mevzuatı |
| `faturaSatirAyikla.ts` | kuruş hesabı, satır toplamı matematiği |
| `faturaMaliyet.ts` | 1 dolar tavanı — senin bütçe kuralın |
| `faturaGorsel.ts` | `sharp` ile görsel boyutlandırma — sunucu işi |
| `supabase/migrations/...publish_invoice_product` | izin, kanıt ve görsel kapıları veritabanında |
| `lib/services/ocr/*.dart`, mobil katman | telefon tarafı, OpenRouter'la ilgisi yok |

Silinirse akış çalışmaz. "Bunları da temizleyelim" diyen rapor yanlıştır.

## C. Bilinçli boşluk — dokümanda karşılığı yok, uydurulmayacak

- **JSON şema** (`FATURA_SEMA`, satır 133): preset dokümanında şema alanı
  listelenmiyor → şema koda kalır.
- **Maliyet okuma**: yanıt gövdesindeki `usage` alanından okunmaya devam.
- **Ücret**: presets dokümanında ücretli bir adım yok. Kural gereği kurulum öncesi
  pricing sayfasından teyit edilecek (Adım 0).

## D. Adımlar — kapılar her adımda

0. **Teyit:** pricing sayfası + mevcut anahtarla 1 canlı istek: `@preset/...`
   gerçekten çağrılıyor mu, JSON ve maliyet aynı mı.
1. **Commitlenmemiş 15 dosyalık iş kararı** (aşağıdaki karar) — kirli ağaçla başlanmaz.
2. 3 preset'i API ile oluştur: `POST /api/v1/presets/<slug>/...` — mevcut
   `OPENROUTER_API_KEY` ile.
3. `faturaGoru.ts`: 3 istek kalıbını preset'e taşı; sabit model/prompt/araç
   satırlarını sil.
4. **Kapılar:** `cd public_web && npx tsc --noEmit && npx vitest run && bash tool/merge-hazir.sh`
5. **Gerçek ölçüm:** gerçek fatura ile 1 okuma — çıktı ve maliyet eskiyle aynı mı.
6. Commit. Dal / ana dal / canlı üçü ayrı yazılır.

**Geri alma:** her adım ayrı commit. Preset iptali dashboard'dan veya slug silinerek.

## E. Taahhüt

Taşınabilir tek merkez `faturaGoru.ts`'in istek kalıplarıdır. "80 dosyanın tamamı
preset'e taşınacak" diyen rapor yanlıştır; taşınmayacakların sebebi B bölümünde yazılı.
