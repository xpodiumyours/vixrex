# Vixrex platform ve bağlantı navigasyonu

> **Güncel bağlantı envanteri (2026-11-05), salt okunur tespit.** Kaynak kod tabanı: `7fa1111c0ca21e11fbdadee22c9ac07a5115c4c9` (`main`). Bu belge canlı fatura testinin, canlı OpenRouter preset içeriğinin veya Graphify indeksinin kanıtı değildir. Makinece okunabilir eşlikçi: [platform-baglanti-haritasi.json](platform-baglanti-haritasi.json).

## Ajan için ilk yönlendirme

1. Önce [Ajan Başlangıç Haritası](AJAN-BASLANGIC.md) ve `AGENTS.md` kurallarını oku.
2. **Kod** için GitHub'da hedef dalın SHA'sını; **canlı** için Vercel üretim commit'ini; **DB** için Supabase canlı ölçümünü; **preset** için OpenRouter canlı presetini ayrı oku. Bunları aynı kabul etme.
3. Bu dosyadaki bağlantı ve değişken **adları** yol göstericidir. Değerler, aktif oturum, canlı hazır olma ve yetki verilmiş olması anlamına gelmez.
4. İlgili kodu değiştirmeden önce Graphify `graph_stats` commit'ini hedef dalla karşılaştır; indeks gerideyse dosya:satır kanıtı kullan, indeks güncelmiş gibi davranma. Hosted varsayılan dal indeksi PR dalını kanıtlamaz.
5. Güvenliğe ilişkin anahtarlar, müşteri faturaları, OAuth jetonları, `.env` içeriği, webhook sırları veya gizli logları GitHub'a/haritaya **yazma**.

## Gerçek fatura veri yolu (main kodu)

```text
Esnafın fatura yüklemesi
  -> Vercel vixrex-public /api/fatura-oku
  -> faturaArkaPlanIslemi.ts
  -> Supabase RPC enqueue_invoice_provider_job
  -> Supabase pg_net -> OpenRouter okuma preset'i
  -> Supabase yanıt kaydı -> Vercel işleyici
  -> Supabase RPC advance_invoice_provider_job
  -> Supabase pg_net -> OpenRouter ürün kartı preset'i
  -> Supabase yanıt kaydı -> /api/cron/fatura-provider callback
  -> Vixrex kart taslağı / esnaf fiyatı / vitrin
```

Bu, kodda görülen yönlendirme ve çağrı zinciridir; ücretli gerçek fatura uçtan uca testi yapılmadı. **OpenRouter ürünün kimliğini ve kart kararını üretir; Vixrex'in hedefi sonucu taşımak ve esnafın fiyat/yayın adımlarını sağlamaktır.** PR #741'in ayrı dalındaki davranış, main veya canlıyla bir tutulmaz.

| İlişki | Kaynak | Yetki / kritik sınır |
|---|---|---|
| GitHub → Vercel `vixrex-public` | Vercel proje kimliği `prj_dCMDIaefrTHg6ysiUDT7veiWI52h` | Git dalından önizleme tetiklenebilir; üretim ayrıca ölçülür |
| GitHub → Vercel `vixrex-app` | Vercel proje kimliği `prj_AfdnDnAcIwSCaJuBoCQh1TP1GvWR` | Ayrı yayın ve ortam |
| Vercel public → Supabase | `public_web/src/lib/supabaseAdmin.ts` | `SUPABASE_SERVICE_ROLE_KEY` yalnız sunucu, tarayıcıya verilmez |
| Vercel public → Supabase fatura RPC | `public_web/src/lib/faturaArkaPlanIslemi.ts:35-49,87-98` | `OPENROUTER_API_KEY` RPC parametresi olarak aktarılıyor; loglanmamalı |
| Supabase → OpenRouter okuma | `supabase/migrations/20261023173000_fatura_kart_preset_uyumu.sql:65-125` | `pg_net` HTTP; `@preset/vixrex-qwen-fatura-okuma-suzme` |
| Supabase → OpenRouter kart | Aynı migration `:6-63` | `pg_net` HTTP; `@preset/urun-kart-olusturucu` |
| Supabase → Vercel callback | Aynı migration `:169-184` | `https://vixrex.com/api/cron/fatura-provider`, callback token gizlidir |
| Vercel app → Supabase | Vercel üretim ortam değişkeni adları | `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` |
| Ajan → Vercel / Supabase / Graphify | `.mcp.json` | MCP tanımı erişim yetkisi veya oturum geçerliliği kanıtı değildir |

### Kayıtlı proje / bağlantı kanıtları

- GitHub kaynak: [Vixrex `main`](https://github.com/xpodiumyours/vixrex/tree/7fa1111c0ca21e11fbdadee22c9ac07a5115c4c9); bu incelemede `main` SHA'sı `7fa1111c0ca21e11fbdadee22c9ac07a5115c4c9`.
- Supabase: proje `chfulefxczbgurtgavtp`, adı `Vixrex Project`; 5 Kasım 2026 proje API yanıtı `ACTIVE_HEALTHY`. Bu yalnız proje durumudur, fatura RPC'sinin uçtan uca çalıştığını kanıtlamaz.
- Vercel: `vixrex-public` ve `vixrex-app` proje kimlikleri ve ortam değişkeni **isimleri** bağlı Vercel üzerinden okundu. Gizli değer çözme işlemi yapılmadı.
- OpenRouter: model/preset tanımları repoda bulunuyor; **canlı preset sürümü ve canlı API erişimi bu kontrolde ölçülmedi**.
- Graphify: `.mcp.json` bağlantısı tanımlı; **güncel `graph_stats` ve otomatik indeksleme bu kontrolde ölçülmedi**.

## Anahtar / konum / kullanım ayrımı

| Değişken (değer YOK) | Nerede görüldü veya tanımlı | İşlev |
|---|---|---|
| `OPENROUTER_API_KEY` | `vixrex-public` production değişken adı doğrulandı; yerelde `public_web/.env.local` | Runtime OpenRouter çağrı anahtarı, sunucu sırrı |
| `OPENROUTER_MANAGEMENT_API_KEY` | `tool/openrouter-preset.sh`, `tool/preset-karsilastir.py` yerel araçları | Yönetim anahtarı; production varlığı **doğrulanmadı** |
| `SUPABASE_SERVICE_ROLE_KEY` | `vixrex-public` production adı doğrulandı | Ayrıcalıklı sunucu erişimi, tarayıcıya **asla** verilmez |
| `SUPABASE_URL` | Her iki Vercel projesi production adı doğrulandı | Supabase proje adresi |
| `SUPABASE_PUBLISHABLE_KEY` | Her iki Vercel projesi production adı doğrulandı | Normal istemci erişimi, RLS gerekli |
| `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` | `vixrex-public` production adları doğrulandı | Tarayıcıya açık, eski uyumluluk değişkenleri |

**Ortam ayrımı:** Production'da bir değişken adının bulunması, yeni bir preview dalında bulunduğunu veya doğru değere sahip olduğunu göstermez. Bazı preview değişkenleri Git dalına özgü kaydedilmiş. Yeni dal için preview envanteri ayrıca ölçülmelidir.

**Dikkat:** Bu harita anahtar kasası değildir. Hiçbir gerçek anahtar, anahtarın kısmi değeri, fingerprint'i, yetkili cevap gövdesi veya müşteri verisi tutulmaz. Yönetim anahtarı, runtime API anahtarının yerine geçmez. Kodda `OPENROUTER_API_KEY`'in Supabase RPC parametresi olarak aktarılması bağlantı şemasında kayıtlıdır; burada davranış değiştirilmiyor.

## Hangi veriye hangi kaynaktan bakılır?

| Soru | Yetkili ölçüm | Sınır |
|---|---|---|
| Hangi Vercel projesi bağlı, hangi değişken **adları** mevcut? | Vercel proje ve env metadata (`decrypt=false`) | Değerin geçerliliği kanıtlanmaz |
| Canlı hangi commit? | Vercel production deployment ve `deploy-info.json` | PR deploy'u üretim değildir |
| Supabase projesi aktif mi? | Supabase proje metadata | RPC, izin, RLS, kayıtları tek başına kanıtlamaz |
| Fatura fonksiyonu canlıda mı? | Supabase üretim RPC / migration envanteri ve güvenli test | GitHub migration dosyası tek başına kanıt değildir |
| OpenRouter anahtarı çalışıyor mu? | Yetkili API kimliği / izin kontrolü; değeri açıklamadan | `GET /api/v1/models` tek başına preset yetkisini kanıtlamaz |
| OpenRouter preset hangi sürüm? | OpenRouter hesabındaki canlı preset | `openrouter/*.json` dosyaları canlı sürüm kanıtı değildir |
| Graphify indeks commit'i nedir? | Graphify `graph_stats` | Dal/PR ve canlı durumu ayrıca doğrulanır |

## Yapılmayanlar ve güncellik sınırı

Bu değişiklik yalnız navigasyon belgesidir. `main`, PR #741, Vercel ayarları, Supabase şeması/verileri, OpenRouter presetleri, API anahtarları ve uygulama kodu değiştirilmez. **Bu bağlantı kaydının güncel olduğu son kaynak kod tabanı:** `7fa1111c0ca21e11fbdadee22c9ac07a5115c4c9` (5 Kasım 2026'da okunmuştur). Sonraki commit ve deploy'larda bu kaydı otomatik güncel sayma. Graphify'ın yeni dala özel indekslemesi GitHub yazımından otomatik olarak doğrulanmış sayılmaz.
