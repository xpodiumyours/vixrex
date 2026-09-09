# Matris Araştırması — Nedir, Nasıl Kurulur (2026-09-08)

Amaç: 6 matrisin ezber değil kaynakla öğrenilmesi. Her bölüm: tanım + kural + Vixrex karşılığı + kaynak.
Kural: Alıntılar web kaynaklarından, yorum yok.

## 1. İzlenebilirlik matrisi (Requirements Traceability Matrix)

Tanım (ISTQB sözlüğü, `https://glossary.istqb.org` üzerinden aktaran `https://istqb-glossary.page/traceability-matrix/`):
"A two-dimensional table, which correlates two entities (e.g., requirements and test cases). The table allows tracing back and forth the links of one entity to the other, thus enabling the determination of coverage achieved and the assessment of impact of proposed changes."

Ne işe yarar (`https://sqadojo.com/learning-hub/traceability-matrix`, `https://www.testrail.com/blog/requirements-traceability-matrix/`):
- Her gereksinimin test edildiğinin kanıtı (ileri izlenebilirlik: gereksinim→test; geri izlenebilirlik: test→gereksinim).
- Değişiklik etki analizi: "şu alan değişti, hangi testler etkilenir?" sorusunun cevabı.
- Denetim kanıtı.

Kurulum kuralları (kaynaklardan derlenen ortak noktalar):
- Her gereksinime tekil ID verilir (örn REQ-001). ID'siz satır matrise giremez.
- İki yönlü bağ: her satırda gereksinim + test(ler) + kusur (varsa).
- Değişiklikte matris güncellenir; test sonunda değil, işle birlikte yazılır. Sık hata: "eksik eşleme" ve "değişiklik sonrası güncellememe".

Vixrex karşılığı: `docs/research/islev-matrisi-2026-09-08.md` — satırlar Flutter ekranı (=gereksinim), sütunlar Next karşılığı + test. Bizim ID'miz dosya yoludur (`lib/screens/...`).

## 2. Karar tablosu (Decision Table)

Tanım: Girdi koşul kombinasyonlarının beklenen çıktılara tabloyla eşlenmesi. Koşul sayısı n ise kural sayısı 2^n olur. Davranışın kombinasyona göre değiştiği iş kurallarında kullanılır (eşdeğer bölmeleme ve sınır analizi yetmediğinde).

Kaynaklar: `https://www.guru99.com/decision-table-testing.html` (giriş/çıktı örneği, 2^n kuralı), `https://www.istqb.guru/decision-tables-equivalence-partitioning-boundary-value-analysis` (üç tekniğin birlikte kullanımı), `https://scaleengineer.com/glossaries/decision-table-testing` (dört kadran: koşullar, koşul alternatifleri, aksiyonlar, aksiyon girdileri).

Vixrex'te nerede gerekir: vitrin yayın kuralları (yayınlı/yayınsız × taslak var/yok × flow_state dolu/boş × şablon seçili/seçili değil → hangi ekran açılır). #423'teki hata ("flow_state doluysa eski kart açıldı") klasik karar-tablosu eksiğidir: kombinasyonlardan biri testte yoktu. Bu tablo kurulursa o sınıf hata biter.

## 3. Yetki / erişim kontrol matrisi (Access Control Matrix)

Tanım (`https://frontegg.com/blog/access-control-matrix`): Özneler (rol/kullanıcı) × nesneler (tablo/sayfa/API) tablosu; her hücrede izin (oku/yaz/sil/yok). Bileşenleri: subjects, objects, permissions/access rights.

Test yöntemi (OWASP WSTG-IDNT-01, `https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/03-Identity_Management_Testing/01-Test_Role_Definitions`):
- Roller belgelenir (test hedefi 1: "Identify and document roles").
- Her rolle diğer rolün işi denenir (yatay/dikey yetki aşımı).
- Eski OWASP kılavuzu cümlesi: "develop a role versus permission matrix" (`kennel209.gitbooks.io/owasp-testing-guide-v4`).

Supabase karşılığı (resmi, `https://supabase.com/docs/guides/database/postgres/row-level-security`):
- "Enable RLS on every table in an exposed schema."
- Roller: `anon` (girişsiz), `authenticated` (girişli), `service_role` (yalnız sunucu, RLS'yi atlar).
- Prosedür: `alter table ... enable row level security` → `revoke all ... from anon, authenticated` → yalnız gereken grant → işlem başına ayrı politika (`select/insert/update/delete`) → her tabloya `supabase/tests/<tablo>_rls.test.sql` → `supabase test db`. "Until the suite passes, you don't know whether the policies do what you intended."
- Test kalıbı: `set local role anon/authenticated` + `throws_ok` (red) / `results_eq` (izin).

Vixrex karşılığı: satırlar = tablolar (`stores`, `store_working_drafts`, `products`, ...), sütunlar = anon/authenticated/sahip-başkası/admin, hücreler = politika + test dosyası. CI'daki `grant-guard` işi bunun otomatik bekçisidir ama matrisin kendisi değildir.

## 4. Route/API denetim listesi

Kaynak (resmi, Next.js `https://nextjs.org/docs/app/guides/data-security` → Auditing bölümü): denetlenecekler `Data Access Layer`, `"use client" files`, `"use server" files`, `/[param]/`, `proxy.ts and route.ts`.

Matrise dönüşümü: satırlar = 43 API route + sayfalar, sütunlar = sunucu mu/istemci mi, secret istiyor mu, `server-only` var mı, rol denetimi var mı. #435'teki `server-only` olayı bu listenin bir satırıdır.

## 5. Ortam / yapılandırma matrisi (Config)

Kaynak (12-factor, `https://12factor.net/config`): "Store config in the environment." Kural: "strict separation of config from code". Turnusol testi: "codebase could be made open source at any moment, without compromising any credentials."

Matrise dönüşümü: satırlar = değişkenler (`SUPABASE_URL`, `SERVICE_ROLE`, `NEXT_PUBLIC_*`, ...), sütunlar = local/preview/prod + gizli mi + önbelleğe gömülü mü (`NEXT_PUBLIC_` build'de gömülür). Vixrex'te `public_web/.env.example` satırları verir, tabloyu vermez. Vercel karşılığı: `https://vercel.com/docs/environment-variables` (ortam başına değer).

## 6. Görsel parity / sözleşme testi

Kaynaklar: Flutter `docs.flutter.dev` (referans değerler), görsel regresyon araç karşılaştırması (`https://uiverify.ai/docs/visual-regression-testing-tools`, `https://crosscheck.cloud/blogs/percy-vs-applitools-vs-chromatic-visual-regression-testing/`): ortak iş — ekran görüntüsünü onaylı tabanla karşılaştır, farkı incelemeye düşür.

Vixrex'in seçtiği yöntem (araçsız, ucuz): Flutter kaynağını dosyadan okuyup CSS değerini denetleyen Vitest sözleşmeleri (#437/438/439'un 3 test dosyası). Ekran görüntüsü karşılaştırmaz, sayıyı karşılaştırır (`220`, `68`, `22px`). Sınırı: yerleşim/taşma gibi görsel hataları yakalamaz — onun için Playwright E2E baselines vardır (yalnız main'de koşar, CLAUDE.md).

## Kaynak listesi

- https://istqb-glossary.page/traceability-matrix/
- https://sqadojo.com/learning-hub/traceability-matrix
- https://www.testrail.com/blog/requirements-traceability-matrix/
- https://www.guru99.com/decision-table-testing.html
- https://www.istqb.guru/decision-tables-equivalence-partitioning-boundary-value-analysis
- https://scaleengineer.com/glossaries/decision-table-testing
- https://frontegg.com/blog/access-control-matrix
- https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/03-Identity_Management_Testing/01-Test_Role_Definitions
- https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://nextjs.org/docs/app/guides/data-security
- https://12factor.net/config
- https://vercel.com/docs/environment-variables
- https://uiverify.ai/docs/visual-regression-testing-tools
