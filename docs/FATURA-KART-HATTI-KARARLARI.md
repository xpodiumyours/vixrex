# Fatura kartı hattı — kusur kapatma planı (karar kaydı)

Tarih: 2026-11-07 · Dayanak: sahadan alınan dört gerçek cevap + resmî platform sözleşmeleri.
Bu belge öneri listesi değil, **karar kaydıdır**: her kararın altında dayanağı yazılıdır.

## 1. Bugünkü ölçüm

| Koşu | Kayıt | Fatura satırı | Üretilen kart | Araç çağrısı |
|---|---|---|---|---|
| `12d7718a` | `KART_YANITI_COZULEMEDI` | 20 | 20 | 30/30 |
| `73718906` | `KART_SATIRLARI_ESLESMEDI` | 7 | 7 | 28 |
| `54ff6387` | `KART_YANITI_COZULEMEDI` | 7 | 7 | 18 |
| `bba4a416` | `KART_YANITI_COZULEMEDI` | 13 | 13 | 26 |

- Aynı baytlar bugün ayrıştırıcıdan **eksiksiz** geçiyor: kart sayısı = fatura satır sayısı
  (test: `public_web/tests/api/fatura-kart-ham-cevaplar.test.ts`).
- Dördünde de veritabanı durumu `failed`, HTTP 200, cevap türü `text/event-stream`.
- Ayrıştırıcı dosyaları son sekiz canlı sürümde birebir aynı (29 Ekim'den beri fark yok).
- Uygulama `failed` kaydı görünce cevabı **hiç okumuyor**, kayıtlı kodu fırlatıyor:
  `public_web/src/lib/faturaArkaPlanIslemi.ts:66`.

Sonuç: cevap sağlam, kayıt "bozuk" diyor. Hangisinin doğru olduğu bugün **kanıtlanamıyor**,
çünkü denemenin kendisi kaydedilmiyor. Plan önce bu kanıt boşluğunu kapatır.

## 2. Kusurlar

| Kod | Nerede | Bugün ne oluyor | Neden önemli |
|---|---|---|---|
| **K1** | `public_web/src/lib/faturaKartPreset.ts:154-198` | Kartı olmayan satır sessizce "Araştırılamadı" oluyor; hata yalnız **hiç** satır eşleşmezse veriliyor (`:198`) | 20 satırın 19'u boş gelse fatura yine "işlendi" görünür — asıl şikâyet bu |
| **K2** | `public_web/src/lib/faturaArkaPlanIslemi.ts:66` | `failed` iş bir daha okunmuyor; aynı fatura hep aynı hatayı alıyor | Kullanıcının çıkış yolu yok; 650 KB cevap veritabanında çürüyor |
| **K3** | `invoice_provider_runs` (tek satır) | Deneme başına kayıt yok: hangi sürüm, hangi bayt, hangi sonuç | "Neden failed" sorusu kanıtla cevaplanamıyor |
| **K4** | `public_web/src/lib/faturaGoru.ts:207` | `tool_calls` gelirse cevabın tamamı atılıyor | OpenRouter'da `tool_calls` normal bitiş sebebidir, hata değil |
| **K5** | `public_web/src/lib/faturaGoru.ts:206` | `finish_reason: length` genel hata sayılıyor | Kesilen cevap tamamen çöpe gidiyor; büyük fatura aynı yerde tekrar tekrar kesilir |
| **K6** | hiçbir yerde | Deneme sayısı, bekleme, hata sınıfı yok; 401 "User not found" 5 kez, 403 5 kez denenmiş | Para ve süre boşa gidiyor; düzelmesi imkânsız hata tekrar deneniyor |
| **K7** | `public_web/src/lib/faturaKartSozlesmesi.ts:167-186` | Boş başlıklı / kimliksiz kart kabul ediliyor | Kullanıcı boş kart görür |
| **K8** | hiçbir yerde | Kapsam oranı (kart çıkan satır / toplam satır) ölçülmüyor | Arıza ancak kullanıcı söyleyince görülür |

## 3. Kararlar

**D1 — Kapsam sözleşmesi (fail-closed).** Kart kümesi, fatura satır kümesine **tam eşit**
olmalı. Eksik varsa iş başarısız sayılır, eksik satır numaraları hata koduna yazılır
(`KART_KAPSAMI_EKSIK`). Bir satır ancak model o satır için `not_researched` döndürdüyse
"Araştırılamadı" olur; "kart gelmedi" ile "kart geldi, bulunamadı" ayrılır.
*Dayanak:* ISO/IEC 25010:2023 "functional correctness" — eksik sonuç doğru sonuç değildir
(https://www.iso.org/standard/78176.html).

**D2 — Doğrulamayı biz yaparız.** `strict: true` garanti değildir; OpenRouter belgesi
sağlayıcıya göre değiştiğini açıkça yazar ("some guarantee schema-conforming output, while
others … treat it as a strong hint"). Bu yüzden şema + `row_id` küme eşitliği + boş başlık
yasağı **bizim** kapımızdır.
*Dayanak:* https://openrouter.ai/docs/features/structured-outputs

**D3 — Hata sınıfları.** Geçici: zaman aşımı, 5xx, bağlantı kopması, akış içi `error`.
Kalıcı: 400/401/402/403/404, şema ihlali, kapsam eksik. Yalnız geçici olan yeniden denenir.
*Dayanak:* AWS Well-Architected REL05-BP03
(https://docs.aws.amazon.com/wellarchitected/latest/framework/rel_mitigate_interaction_failure_limit_retries.html)

**D4 — Deneme politikası.** Toplam 3 deneme; tam jitter'lı üstel geri çekilme; taban 2 sn,
üst sınır 20 sn; deneme sayısı ve son hata kayda geçer.
*Dayanak:* AWS Builders' Library "Timeouts, retries, and backoff with jitter"
(https://builder.aws.com/content/3EumjoZascWd1oZiEgL8ORlv3qE/timeouts-retries-and-backoff-with-jitter)

**D5 — Tekillik (idempotency).** İş kimliği tekillik anahtarıdır; kartlar `(job_id, row_id)`
üzerine yazılır; aynı fatura yeniden gönderilirse yeni iş açılmaz, aynı iş kaldığı yerden
devam eder; tekrar deneme kayıt çoğaltmaz.
*Dayanak:* PostgreSQL `INSERT … ON CONFLICT`
(https://www.postgresql.org/docs/current/sql-insert.html) · AWS: "yan etkili API'ler
idempotency sağlamadıkça tekrar denenmez" (aynı Builders' Library belgesi).

**D6 — Cevap tek kaynak.** Gövde bir kez yazılır; yanına `sha256`, `content_type`,
`finish_reason` ve `attempt` eklenir. `state=received` yalnız gövde tamamlandıktan sonra
yazılır ve okuma daima bu baytlardan yapılır. Bugünkü çelişki (kayıt "bozuk", baytlar sağlam)
bu adımla bir daha oluşamaz.
*Dayanak:* D3/D5 ile aynı; ayrıca ISO 25010 "reliability / fault tolerance".

**D7 — Denetim izi.** Yalnız ekleme yapılan `invoice_job_events`: `job_id, attempt,
from_state, to_state, reason_code, http, body_sha256, actor, created_at`. Sır, anahtar ve
kişisel veri yazılmaz; saklama süresi belgede yazılır.
*Dayanak:* OWASP Logging Cheat Sheet ("when, where, who and what")
https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html · NIST SP 800-92
(https://csrc.nist.gov/pubs/sp/800/92/final) · OWASP Top 10:2025 A09 — "append-only
database tables" (https://owasp.org/Top10/2025/A09_2025-Security_Logging_and_Alerting_Failures)

**D8 — Akış sözleşmesi.** `[DONE]` ve `finish_reason` zorunlu; `usage` son parçada
`[DONE]`'dan hemen önce gelir; akış içi hata HTTP **200** ile `finish_reason: "error"` ve üst
düzey `error` olarak gelir; `length` hata değil **kesilme**dir. Kesilmede cevap atılmaz:
satırlar gruplara bölünüp (ör. 8 satır) yeniden istenir, sonuç yine D1 kapısından geçer.
*Dayanak:* https://openrouter.ai/docs/api-reference/streaming ·
https://openrouter.ai/docs/api-reference/errors-and-debugging

**D9 — Araç çağrısı.** Bu preset JSON üretmelidir; `tool_calls` gelirse bir kez araçsız
yeniden denenir, yine gelirse kalıcı hata olarak kaydedilir — cevap silinmez.
*Dayanak:* aynı iki belge (normalize `finish_reason` değerleri:
`tool_calls, stop, length, content_filter, error`).

**D10 — Yerleşim.** Model çağrısı dakikalar sürebilir; Vercel fonksiyonu en fazla 800 sn
(Pro), aşılırsa 504 döner ve `waitUntil` de aynı süreye bağlıdır. Bu yüzden uzun çağrı
**kuyruk + kısa fonksiyon + kiralama (lease)** ile yürür; istek yolunda beklenmez.
*Dayanak:* https://vercel.com/docs/functions/limitations ·
https://vercel.com/docs/background-workers

**D11 — Kuyruk.** Supabase Queues (pgmq): görünürlük süresi dolunca mesaj geri gelir
(otomatik tekrar), başarılı iş arşive gider (denetim ve tekrar oynatma için). `unlogged` kuyruk
yasak (çökmede mesaj kaybı). Mesaj, durum değişikliğiyle **aynı işlemde** yazılır.
*Dayanak:* https://supabase.com/docs/guides/queues/pgmq ·
https://supabase.com/kb/faqs/background-jobs/background-job-processing

**D12 — Gözlem.** Her koşuda `satir_sayisi, kart_sayisi, deneme, sure, finish_reason`
kaydedilir; kapsam %100 değilse uyarı üretilir; haftada bir denetim betiği çalışır
(kapsam oranı, terminal hata dağılımı, kuyrukta bekleyen iş).

## 4. Uygulama sırası

| Adım | İçerik | Kusur | Veritabanı değişikliği |
|---|---|---|---|
| **P1** | Kapsam kapısı + boş başlık kapısı + "yeniden dene" düğmesi | K1, K7 | Yok |
| **P2** | Deneme/olay tablosu, hata sınıflandırma, geri çekilme | K2, K3, K6, K8 | Var (yalnız yeni tablo/kolon) |
| **P3** | Akış sözleşmesi: `length` → gruplama, `tool_calls`, 200 içi hata | K4, K5 | Yok |
| **P4** | pgmq kuyruğu + kiralama + tekrar oynatma (replay) kılavuzu | K2 (devam) | Var |
| **P5** | Haftalık denetim betiği + panel göstergesi | K8 | Yok |

Her adım tek PR: kapılar (vitest, tsc, lint, üretim derlemesi), gövdede gerçek `dosya:satır`
taşıyan `Graphify etki:` satırı, madde başına öncesi/sonrası ölçüm. P1–P3 tek başına değer
üretir; P4 ertelenebilir.

## 5. "Bitti" ölçütü

1. Kapsamı %100 olmayan hiçbir koşu "işlendi" olamaz — testle kilitli.
2. Her `failed` kaydın en az bir olay satırı ve `body_sha256` değeri vardır.
3. Aynı fatura ikinci kez gönderildiğinde yeni iş açılmaz; kaldığı yerden devam eder.
4. 401 tek denemede biter ve kullanıcıya "anahtar geçersiz" der.
5. Aynı girdi her oynatmada aynı sonucu verir (deterministik ayrıştırma testi).

## 6. Risk ve geri alma

- P1 ilk gün bazı faturaları "başarısız" gösterecek; bu **doğru** davranıştır, ama tek tuşla
  yeniden deneme olmadan kullanıcıyı kilitler — bu yüzden yeniden deneme düğmesi P1'in içinde.
- P2/P4 migration'ları yalnız ekleme yapar; mevcut tablolara dokunmaz. Geri alma: yeni tabloyu
  düşür, kodu eski dala al.
- P4 en riskli parça; pgmq'ya geçmeden P1–P3 canlıya çıkabilir.

## 8. P3 — akış sözleşmesi (2026-11-07)

Resmî sözleşme: OpenRouter `finish_reason` değerlerini `tool_calls, stop, length, content_filter, error`
olarak normalleştirir; `tool_calls` normal bitiştir, hata değildir. Akış sırasında hata olursa HTTP 200
kalır, hata gövdede `error` + `finish_reason: "error"` olarak gelir.
*Dayanak:* https://openrouter.ai/docs/api_reference/overview · https://openrouter.ai/docs/api-reference/streaming

Düzeltilen kayıplar:

- **`length`** — cevabın tamamı atılıyordu. Artık kesik gövdeden tamamlanmış satır nesneleri çıkarılır
  (`public_web/src/lib/faturaKesikKurtarma.ts:9`), sonuç `kesik: true` ve `OKUYUCU_KESIK_CEVAP` uyarısıyla
  döner (`public_web/src/lib/faturaGoru.ts:220`). Kapsam kapısı (P1) bu kaydı "işlendi" saymaz.
- **`tool_calls`** — parçalar `index`e göre birleştirilir (`public_web/src/lib/openrouterYanitAkisi.ts:70`),
  `function.arguments` gövdesi cevap sayılır (`public_web/src/lib/faturaGoru.ts:203`,
  `public_web/src/lib/faturaKartSozlesmesi.ts:160`).
- **200 içi hata** — 401/403 → `OKUYUCU_ANAHTAR_GECERSIZ`, 402 → `OKUYUCU_BAKIYE_BITTI`, 429 → sınır/kota,
  404 → model yok (`public_web/src/lib/openrouterYanitAkisi.ts:20`).

Bilinçli sözleşme değişikliği: `public_web/tests/api/fatura-preset-sozlesmesi.test.ts` "yarım yanıt
yayın verisine çevrilmez" diyordu; tamamlanmış gövde artık kesik bitiş sebebiyle atılmıyor, test yeni
sözleşmeye çevrildi (silinmedi).

Sınır: görsel hiçbir yerde saklanmadığı için (`invoice_provider_runs` yalnız yanıtı tutar) kesilen okumayı
ikinci çağrıyla tamamlamak bugünkü şemayla mümkün değil; bu P4'ün (kuyruk + gövde saklama) işi.

Ölçüm: 302 test dosyası / 2267 test geçti, `tsc` ve lint temiz; yeni `public_web/tests/fatura-kesik-cevap.test.ts`
(6 test) kesik satır, araç çağrısı birleştirme, kart kurtarma ve 200 içi hata kodlarını kilitler.
