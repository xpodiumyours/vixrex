# VixRex doğal dil mühendisliği katmanları — 2026-08-09

## Sonuç

PR #79 doğru temeli kurdu: tek başlangıç, ince model adaptörleri, salt-okunur
skill yönlendirmesi, GitHub Issue belleği ve PR kanıt sözleşmesi. Fakat bu temel
tek başına bir ajanın doğal dilde verilen büyük işi uçtan uca doğru tamamlamasını
garanti etmez.

Claude Code'un aynı gün verdiği iki öz-eleştiri, eksik katmanı görünür kıldı:
ajan PR açıklamasını bağımsız kanıt gibi kullanmış; gerçek diff'i, GitHub
Issue'larını, oturum/env kodunu ve worktree durumunu yeterince incelememiştir.
Başka bir taramada ise donmuş belgeleri fark etmiş ama bu belgelerin çalışır
durumla çelişmesini önleyen bir mekanizma sunmamıştır. Bu bir model kişiliği
sorunu değil, **plan öncesi durum edinimi ve kanıt provenance'ı olmayan harness
sorunudur**.

Sıradaki yatırım daha fazla kural veya daha uzun prompt olmamalıdır. VixRex'in
eksik kalan kısmı, ajanın yaptığı işi kendi başına çalıştırabildiği ve sonucunu
gerçek kullanıcı davranışıyla ölçebildiği **mühendislik geri bildirim döngüsüdür**.

Hedef sistem şu sonucu üretmelidir:

> Casper isteğini doğal dille anlatır. Ajan bunu küçük ve doğrulanabilir bir iş
> sözleşmesine çevirir; izole ortamda uygular; değişiklik türüne uygun kanıtı
> üretir; preview üzerinde doğrular; yalnız ürün kararı, geri döndürülemez işlem,
> canlı sistem veya ücret gerektiğinde Casper'a döner.

Bu çalışma araştırma ve tasarım kaydıdır. Canlı veritabanına, Vercel ayarlarına,
branch protection'a veya ücretli modele dokunulmamıştır.

## PR #79'dan sonra mevcut durum

### Güçlü temel

- `AGENTS.md` yaklaşık 90 satırlık tek başlangıçtır; Claude, Gemini, Cursor ve
  Copilot adaptörleri yalnız bu dosyaya yönlenir.
- `vixrex-router` yalnız en küçük skill zincirini seçer ve yetki üretmez.
- Aktif görev kaynağı GitHub Issue'dur; kök plan dosyası kullanılmaz.
- Ajan sistemi doktoru adaptör, router, skill yolu, etiket ve Obsidian bağlantı
  hatalarını fixture'larla yakalar.
- Flutter ve Next.js unit/widget/Vitest paketleri PR'larda çalışır.
- Migration dosya adları, test silme/susturma ve PR gövdesi için hızlı statik
  bekçiler vardır.

### Ölçülen açıklar

| Alan | 2026-08-09 kanıtı | Etkisi |
|---|---|---|
| Zorunlu CI | `main` yalnız `CodeQL` ve iki Vercel kontrolünü zorunlu tutuyor; Flutter, Next.js ve `verify-protected-tests` branch protection'da yok | Kırmızı proje testiyle merge teknik olarak mümkün |
| PR sözleşmesi | `.github/scripts/verify_pr_contract.py` her değişiklikte kırmızı kanıt metni istiyor, değişiklik türünü bilmiyor | Doküman/refaktör işinde uydurma kırmızı kanıtı teşvik edebilir |
| Migration kanıtı | `.github/scripts/verify_migrations.py` yalnız dosya adı ve sürüm benzersizliği kontrol ediyor | “18 migration geçti” ifadesi gerçek `db reset` kanıtı değil |
| Yerel Supabase | `supabase/seed.sql` var, fakat sürümlenen `supabase/config.toml` yok | Repo temiz makinede yerel DB'yi tek komutla kuramıyor |
| Veritabanı testleri | Tek SQL smoke, demo içeriğini sayıyor; RLS/rol/RPC yetkisi testi yok | `edit_token`, tenant ve RLS kaçakları statik testten geçebilir |
| Playwright | `playwright.config.ts` varsayılan olarak canlı Vercel'i kullanıyor; local `webServer` ve fixture yok | Stateful E2E izole ve tekrarlanabilir değil |
| False-green E2E | Bazı spec'ler öğe yoksa assertion yapmıyor; bazıları `200/302/404` sonuçlarının tümünü kabul ediyor | Akış tamamen kaybolsa bile test yeşil olabilir |
| Flutter E2E | `integration_test` dosyaları kendi yorumlarında gerçek E2E olmadığını, widget smoke olduğunu söylüyor | Flutter → Supabase → Next.js yolculuğu test edilmiyor |
| CI E2E | Varsayılan CI ne Flutter `integration_test` ne de Playwright çalıştırıyor | Kullanıcı yolculuğu merge öncesi kanıtlanmıyor |
| Test şekli | 124 test dosyasının 36'sı production kaynak metnini doğrudan okuyor; 16 dosyada widget testi, 7 Playwright spec'i var | Mimari sözleşme güçlü, gerçek davranış kanıtı dengesiz |
| Coverage | Flutter/Next.js için coverage eşiği veya change-scoped mutation sinyali yok | Test sayısı, kritik davranışın gerçekten bağlı olduğunu göstermiyor |
| Worktree çalıştırma | `dev.ps1` sabit 3000/5000 portlarını kullanıyor, GUI penceresi açıyor ve `dart_defines.local.json` dosyasını değiştiriyor | Paralel ajanlar çakışabilir; temiz worktree tek komutla kalkmaz |
| Mimari seam | Üretim kodunda 600 satırı aşan en az 19 dosya var; öne çıkanlar 1420, 1186, 1154 ve 1105 satır | Büyük işte doğru sahipliği bulmak ve kapsamı korumak zorlaşıyor |
| Ürün bağlamı | `AGENTS.md` `CONTEXT.md` ve `docs/adr/`a yönlendiriyor; ikisi de henüz yok | Kalıcı kararlar çoğunlukla kurallar ve tarihsel belgeler arasında kalıyor |
| CODEOWNERS | Dosya var fakat bazı desenler gerçek contract test yerleşimiyle eşleşmiyor; branch protection review istemiyor | Sahiplik bildiriliyor fakat mekanik onay kapısı oluşmuyor |
| Issue güncelliği | #76 kapalı olmasına rağmen bütün görev kutuları boş; #32 Next.js kapısını yapılmamış gösterirken CI bunu çalıştırıyor; #39 silinmiş kök `implementation_plan.md` dosyasını zorunlu kaynak diye gösteriyor | Issue hedef belleği olabilir, fakat tek başına mevcut durum kanıtı olamaz |
| PR iddia provenance'ı | #74 gövdesi canlı migration ve veri doğrulaması bildiriyor; aynı PR geçmişinde migration'ın gönderilemediğini söyleyen commit ve bağımsız artefakta bağlanmamış doğrulama metni var | “Canlıda doğrulandı” cümlesinin kim, hangi SHA/URL/komutla doğruladığı yeniden üretilemiyor |
| Oturum/env belirsizliği | `ownerSession.ts`, API rotası, testler ve `.env.example` içinde `OWNER_SESSION_SECRET` sözleşmesi var; canlı Vercel değerinin varlığı repodan görülemiyor | Ajan “yok” veya “çalışıyor” demek yerine kod ile canlı durum arasındaki bilinmeyeni açıkça işaretlemeli |
| Donmuş belge sinyali | `vixrex-is-kuyrugu.md` mevcut `main` veya worktree'lerde bulunmuyor; `docs/durum.md` ise güncel iş listesi değil, Issue'lara yönlendiren statik bir rota sayfası | Dosya adı hatırlamak veya “genel tarama” yapmak güvenilir state acquisition değildir |

## Kanıt hiyerarşisi ve durum sözleşmesi

Hedef ile mevcut durum aynı kaynak değildir:

- **İstenen durum ve kapsam:** bağlı GitHub Issue, onaylı karar/ADR ve kullanıcı
  talebi.
- **Mevcut çalışır durum:** aynı HEAD SHA'da çalışan komut ve ürettiği artefakt,
  gerçek diff, executable config/migration/test ve kaynak kod.
- **Anlatı:** PR açıklaması, commit mesajı ve durum notu yalnız iddia veya indeks
  kabul edilir; daha güçlü kanıtın yerine geçmez.

Çelişkide aşağıdaki öncelik kullanılır:

```text
çalışan komut + artefakt
  > repo durumu ve gerçek diff
  > executable config / migration / test / kaynak kod
  > Issue / onaylı ADR
  > genel doküman
  > PR başlığı, PR gövdesi ve commit mesajı
```

Her önemli sonuç üç durumdan biriyle raporlanmalıdır:

- `verified`: kaynak, zaman ve HEAD SHA ile bağımsız doğrulandı.
- `contradicted`: daha güçlü bir kaynak iddiayla çelişiyor.
- `unverified`: gerekli canlı/ücretli/yetkili kontrol yapılmadı; ne doğru ne yanlış
  ilan edilir.

Plan öncesi tek bir salt-okunur komut şu manifesti üretmelidir:

```text
.vixrex-dev/<worktree-id>/<run-id>/
  evidence.json
  summary.md
```

Manifest; Issue URL/güncelleme zamanı/gövde hash'i, branch/base/head/merge-base
SHA'ları, worktree ve dirty dosyalar, gerçek diff, incelenen dosyalar, env
değerlerini göstermeden anahtarların varlığı ve kaynağı, seçilen risk şeridi,
çalıştırılan komut/exit-code ve üretilen log/trace/screenshot yollarını tutar.
Plan ancak gerekli başlangıç kanıtları toplandıktan ve çelişkiler görünür hale
geldikten sonra kurulur.

## Araştırmadan çıkan ilkeler

### 1. Prompt değil, arayüz ve geri bildirim döngüsü

SWE-agent araştırması, ajan-bilgisayar arayüzünün dosya gezme, düzenleme ve test
çalıştırma başarısını doğrudan etkilediğini gösteriyor. Uzun bağlam araştırması
da ilgili bilginin konumuna göre performansın düşebildiğini gösteriyor. Sonuç:
`AGENTS.md` harita olarak kısa kalmalı; bütün skill ve planlar her istekte
bağlama doldurulmamalıdır.

- [SWE-agent: Agent-Computer Interfaces](https://arxiv.org/abs/2405.15793)
- [Lost in the Middle](https://arxiv.org/abs/2307.03172)
- [Codex AGENTS.md keşfi](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [Claude Code bağlam maliyetleri](https://code.claude.com/docs/en/features-overview)

### 2. Büyük görev tek parça güvenilir değildir

Uzun yazılım görevlerinde başarı, görev süresi ve dağınıklığı arttıkça düşüyor.
Bu nedenle yalnız satır sayısına dayalı evrensel bir yasak yerine şu sinyaller
birlikte kullanılmalıdır: insan süre tahmini, etkilenen sahip modül sayısı,
belirsiz karar sayısı, canlı veri etkisi ve geri dönüş zorluğu.

- [Measuring AI Ability to Complete Long Software Tasks](https://arxiv.org/abs/2503.14499)

Eşik aşılırsa ajan durup işi kullanıcıya geri fırlatmamalı; aynı hedefi çalışan
küçük dikey dilimlere bölmeli ve ilerlemeyi Issue üzerinde tutmalıdır.

### 3. “Test var” değil, davranışa bağlı test var

SWT-Bench, fail-to-pass testlerinin patch seçme doğruluğunu yükselttiğini
gösteriyor. OpenAI eval rehberi ise görev-özel vaka seti, sürekli değerlendirme,
log toplama ve insan kalibrasyonu öneriyor; “çalışıyor gibi” değerlendirmeyi
anti-pattern sayıyor.

- [SWT-Bench](https://www.sri.inf.ethz.ch/publications/muendler2024swtbench)
- [OpenAI evaluation best practices](https://developers.openai.com/api/docs/guides/evaluation-best-practices)
- [OpenAI agent workflow evals](https://developers.openai.com/api/docs/guides/agent-evals)

Kaynak metni okuyan contract testleri mimari kararlar için kalabilir; kullanıcı
davranışını kanıtladıkları iddia edilmemelidir.

### 4. İzinler risk oranlı olmalı

Repo içi okuma, arama, küçük düzenleme ve hedefli testler sürtünmesiz olmalıdır.
Ağ, workspace dışı yazma, ücretli çağrı, destructive Git, migration uygulama,
canlı veri, merge ve deploy ayrı onay sınırında kalmalıdır.

- [Codex sandbox ve onaylar](https://learn.chatgpt.com/docs/agent-approvals-security)
- [Codex sandbox profilleri](https://learn.chatgpt.com/docs/sandboxing)
- [Gemini Plan Mode](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/plan-mode.md)

### 5. Yerel veri katmanı yeniden üretilebilir olmalı

Supabase'in güncel akışı `config.toml`, migration, seed, `db reset` ve RLS/RPC
testlerini sürümlenen repo yüzeyi olarak ele alıyor. 2026 değişikliğiyle yeni
tabloların Data API erişimi de yalnız RLS ile değil, açık `GRANT` davranışıyla
birlikte doğrulanmalıdır.

- [Supabase local development](https://supabase.com/docs/guides/local-development/cli-workflows)
- [Supabase database testing](https://supabase.com/docs/guides/local-development/testing/overview)
- [Data API tablo erişimi değişikliği](https://supabase.com/changelog/45329-breaking-change-tables-not-exposed-to-data-and-graphql-api-automatically)

### 6. Uzun işin belleği aynı hedefte kalmalı

Uzun işte sonuç, sınırlar ve doğrulama ölçütü baştan yazılmalı; ilgili çalışma
aynı oturumda sürdürülmeli; yalnız bağımsız işler ayrı chat/worktree'de paralel
gitmelidir. İki ajan aynı dosyalara yazmamalıdır.

- [OpenAI uzun süreli çalışma rehberi](https://learn.chatgpt.com/docs/long-running-work)

## Önerilen uçtan uca akış

```text
Doğal dil isteği
  → salt-okunur durum/provenance snapshot'ı
  → iddia–gerçek çelişkilerini ve bilinmeyenleri raporla
  → küçük görev sözleşmesi
  → risk/değişiklik türü seçimi
  → izole worktree + çalışır yerel ortam
  → uygun kırmızı/karakterizasyon kanıtı
  → en küçük production değişikliği
  → hedefli yeşil + yüzey testleri
  → code-review + scope kontrolü
  → preview/kritik yolculuk kanıtı
  → migration gerekiyorsa DB önce
  → insanın merge/yayın kararı
  → iki production yüzeyi için ayrı smoke
  → kaçan hata eval setine eklenir
```

## Üç esnek çalışma şeridi

| Şerit | Örnek | Plan | Kanıt | Onay |
|---|---|---|---|---|
| Hızlı | Doküman, agent metadata, biçim, runtime davranışı olmayan küçük bakım | Uzun plan yok; amaç ve kapsam yeterli | Statik doctor/lint; `Kırmızı: N/A — somut neden` | Repo içi geri alınabilir iş sürtünmesiz |
| Standart | Bug, yeni davranış, küçük refaktör | Issue içinde kısa sonuç/kapsam/kabul | Bug/feature: gerçek red→green; refaktör: aynı karakterizasyon önce/sonra | PR ve normal review |
| Yüksek risk | Auth, token, RLS, migration, canlı veri, silme, ödeme, çok yüzeyli değişiklik | Açık plan, sahip modül, veri ve rollback | Hedefli test + gerçek DB/integration/E2E + preview | Canlı/ücretli/geri döndürülemez adım ve merge insanda |

Görev küçüklüğü güvenlik riskini düşürmez. Tek satırlık RLS veya token değişikliği
yine yüksek risk şeridindedir.

## Sert kapı, uyarı ve isteğe bağlı sinyal ayrımı

### Sert ve deterministik olmalı

- Secret sızması, yetkisiz dış yazma ve destructive işlem.
- Canlı DB, migration uygulama, ücretli model, merge ve deploy için yetki.
- Gerçek CI regresyonu.
- Migration değiştiğinde sıfırdan yerel zincirin uygulanamaması.
- Davranış değişikliğinde değişiklik türüne uygun kanıtın olmaması.
- Güvenlik/tenant/token sınırında negatif testin olmaması.

### Önce raporlamalı, otomatik bloklamamalı

- Dosya/satır/diff büyüklüğü.
- Plansız görünen ek dosya.
- Coverage yüzdesi.
- Flake şüphesi veya retry ile geçen test.
- Model tabanlı review bulgusu.
- Eski belge veya olası mimari borç.

Bu sinyaller iki hafta veya en az on PR boyunca ölçülmeden sert kapıya
dönüşmemelidir. Tekrarlanan ve düşük false-positive üreten bir hata sınıfı
kanıtlanırsa yalnız o invariant mekanik kapı yapılır.

### İsteğe bağlı ve bütçeli olmalı

- Claude/Codex/Gemini/OpenCode çapraz-model smoke.
- Üç tekrarlı agent patch eval koşusu.
- Mutation testinin geniş paketi.
- Tam cihaz matrisi veya tüm görsel regresyon paketi.

Bu işlemler CI'da kendiliğinden ücret üretmemelidir. Her koşum model/sürüm,
bütçe tavanı, süre ve sonuçla kaydedilmelidir. Tek bir model smoke koşusu başarı
kanıtı değildir.

## Uygulama katmanları ve önerilen sıra

### Katman 0 — Kanıtlı durum edinimi

Amaç: ajanın planı PR metni, donmuş not veya yüzeysel `git status` üzerine
kurmasını mekanik olarak engellemek.

- `vixrex evidence --issue <n>` benzeri tek salt-okunur komut branch, worktree,
  merge-base, Issue, ilişkili PR, gerçek diff, ilgili sahip dosyalar ve
  executable test/config yüzeyini toplar.
- Secret değerleri asla yazılmaz; yalnız anahtarın var/yok durumu, kaynağı ve
  redakte edilmiş fingerprint'i kaydedilir.
- Kanıt her zaman HEAD SHA'ya bağlanır. Başka SHA'da alınmış test sonucu geçerli
  yeşil sayılamaz.
- PR metni manifest üretmez; manifestten PR kanıt özeti üretilir.
- Yüksek riskli `supabase/`, auth/token, workflow, deploy veya canlı yüzey diff'i
  Issue kapsamı dışında ise sert durur. Normal kapsam şüphesi önce uyarı olur.
- İlk kırmızı fixture: “PR bütün testler geçti diyor; Issue yalnız WhatsApp
  düzeltmesi istiyor; diff auth+migration içeriyor; kanıtta HEAD SHA yok.”
  Beklenen sonuç: `unbound evidence`, `high-risk unapproved path` ve
  `issue-scope mismatch` ile exit 1.

### Katman 1 — Adaptif iş ve PR sözleşmesi

Amaç: PR #79'un kapısını gerçek değişiklik türüne uydurmak.

- `Değişiklik Türü`: `bug | feature | refactor | docs | agent-metadata`.
- `bug/feature`: base SHA'da beklenen nedenle kırmızı, patch sonrası yeşil.
- `refactor`: aynı characterization paketi önce ve sonra yeşil; uydurma kırmızı yok.
- `docs/agent-metadata`: yalnız somut gerekçeli `N/A` kabul; çıplak `N/A` ve
  placeholder reddedilir.
- Test silme/taşıma mutlak yasak değil; Issue gerekçesi + sahip onayı + yerine
  gelen kanıtla mümkün olmalıdır.
- Önce report-only; false-positive görülmezse Flutter, Next.js ve kalite işi
  branch protection'da required yapılmalıdır.

### Katman 2 — Tek komutla izole worktree ortamı

Amaç: ajanın uygulamayı insan eli olmadan açıp gözlemleyebilmesi.

- Dinamik ve çakışmayan Flutter/Next/Supabase portları.
- Gizli dosyaları değiştirmeyen, yalnız okuyan env üretimi.
- Sürümlenen `supabase/config.toml`, migration + seed ile bilinen durum.
- `start`, `ready`, `logs`, `stop` komutları; GUI penceresi zorunluluğu yok.
- Hazır olduğunda makinece okunur URL/port çıktısı.
- Her worktree için ayrı test verisi ve temiz kapanış.

### Katman 3 — Kritik kullanıcı yolculukları

İlk küçük portföy:

1. Flutter'da vitrin oluştur → zorunlu alanları doldur → taslak preview bağlantısı.
2. Sahip oturumu aç → bir alanı düzenle → ziyaretçi hâlâ eskiyi görür → yayınla
   → ziyaretçi yeniyi görür → vazgeç geri döner.
3. Public vitrin açılır → başlık/ürün/WhatsApp/SEO gerçek içerikle görünür.
4. Yetkisiz kullanıcı başka mağazanın taslağını okuyamaz/yazamaz; token tarayıcı
   çıktısına sızmaz.
5. Boş DB'de migration + seed → uygulama iki yüzeyiyle açılır.

Kadans:

- Her PR: hızlı unit/widget/Vitest + değişen yüzeye ait en küçük kritik smoke.
- Risk tetiklemeli: auth/token/RLS/migration ve cross-surface değişiklikte ilgili E2E.
- Gece/elle: geniş Playwright, görsel regresyon ve cihaz matrisi.
- Merge sonrası: canlıda yalnız read-only smoke; stateful test üretimde çalışmaz.

Flutter'ın resmî integration test komutu ve Playwright'ın CI/trace desteği bu
yüzeyleri doğrudan destekler:

- [Flutter integration testing](https://docs.flutter.dev/testing/integration-tests)
- [Playwright CI](https://playwright.dev/docs/ci-intro)

### Katman 4 — Gerçek migration ve RLS doğrulaması

- `supabase db reset` ile sıfırdan zincir.
- pgTAP veya eşdeğeriyle tablo, fonksiyon ve policy varlığı.
- `anon`, `authenticated`, farklı mağaza sahibi ve yetkisiz rol için negatif
  CRUD/RPC testleri.
- Data API için açık grant + RLS birlikte doğrulanır.
- Yalnız migration değişen PR'larda ağır DB işi; her doküman PR'ında çalışmaz.

### Katman 5 — VixRex agent eval seti

İki ayrı set gerekir:

**Routing set — ücretsiz/statik başlangıç**

- 20–30 gerçek Türkçe istek.
- Beklenen risk şeridi, skill zinciri, okunacak kaynak ve yasak yan etki.
- Ölçü: zorunlu route recall, exact match, yetkisiz write sayısı, git değişmedi.

**Patch set — kontrollü ve gerektiğinde ücretli**

- 12–20 kapanmış VixRex issue'su, sabit base SHA ve saklı regression testi.
- İlk vakalar: sahip panelinin açılmaması, `edit_token` sızıntısı, bozuk migration,
  yanlış davranışı kilitleyen test, React key çakışması, GPS adres akışı ve bayat
  preview/cache.
- Ölçü: pass@1, üç koşu kararlılığı, fail-to-pass/pass-to-pass, plansız dosya,
  süre, maliyet, insan müdahalesi ve 30 günlük revert/incident.

Router veya skill değişikliği önce routing setinde; daha seyrek olarak patch
setinde ölçülmelidir. Eval sonucu insan tarafından örneklenerek denetlenmelidir.

### Katman 6 — Ürün ve mimari okunabilirliği

- Yeni dev bir ürün anayasası yazılmaz.
- `repository-guide.md` gerçek komutları ve sahip modülleri göstermeye devam eder.
- Terim veya kalıcı karar gerçekten netleştiğinde küçük `CONTEXT.md`/ADR eklenir;
  her iş öncesi belge töreni yapılmaz.
- Büyük modüller otomatik olarak bloklanmaz; rapor, yeni sorumluluğun hangi sahip
  modüle ayrılacağını görünür kılar.
- Tarihsel planlar aktif karar kaynağı gibi görünmeyecek şekilde indekslenir.

### Katman 7 — Preview, merge ve yayın kanıtı

- İki Vercel preview ayrı kontrol edilir.
- Migration gerekiyorsa canlıya önce DB uygulanır; ardından kod merge edilir.
- Merge sonrası iki production URL'si ayrı read-only smoke alır.
- Başarısız smoke otomatik “deploy başarılı” sayılmaz; issue açar ve rollback
  kararını insana getirir.
- GitHub Environment/Vercel ücretli koruma ancak mevcut ücretsiz akış yetersiz
  kalırsa ayrıca değerlendirilir; bu plan yeni abonelik gerektirmez.

## İlk tracer-bullet paketleri

Her biri ayrı, küçük ve geri alınabilir PR olmalıdır:

1. SHA'ya bağlı `doctor/evidence` manifestini fixture tabanlı testlerle ekle;
   önce report-only çalıştır.
2. PR sözleşmesine değişiklik türü, koşullu kırmızı kanıt ve manifest bağlantısı
   ekle; PR gövdesini manifestten üret.
3. `supabase/config.toml` + boş DB reset + benzersiz fixture + tek RLS negatif
   testini çalıştır.
4. Worktree için çakışmayan portlarla `up/status/logs/down` omurgasını kur;
   sabit uyku yerine readiness ve PID/log kaydı kullan.
5. Next sağlık uç noktası, browser console/pageerror/network 5xx ve ortak run-id
   ile minimum gözlenebilirlik ekle.
6. Mevcut Playwright false-green assertion'larını düzelt; canlı default'u kaldır;
   retry=0 yerel altın sahip düzenle/yayınla/vazgeç yolculuğunu çalıştır.
7. 20–30 promptluk ücretsiz routing eval setini ve JSONL sonuç şemasını ekle.
8. On PR'lık gözlemden sonra yalnız kararlı CI kontrollerini required yap; merge
   sonrası iki Vercel yüzeyi için ayrı read-only smoke ekle.

## Başarı ölçütleri

Sistem “çok kural yazıldı” diye değil, şu sonuçlarla başarılı sayılır:

- Küçük işlerin doğal dil isteğinden çalışan PR'a insan müdahalesiz geçme oranı.
- Zorunlu skill/risk rotasında %100 recall.
- Yetkisiz canlı/dış/ücretli işlem sayısı: sıfır.
- Davranış değişikliklerinde geçerli red→green veya characterization kanıtı.
- Plansız dosya ve kapsam sapması oranının düşmesi.
- Retry ile geçen testlerin `unstable` olarak görünmesi.
- PR sonrası 14/30 günlük revert ve production kaçak hata oranının düşmesi.
- Ajan/model değiştiğinde aynı görev setindeki başarı farkının ölçülebilmesi.
- “Çalışıyor/canlıda doğrulandı” iddialarının kaynak, zaman ve HEAD SHA olmadan
  üretilememesi; bilinmeyenlerin `unverified` olarak kalması.
- Issue, durum belgesi ve executable gerçeklik çelişkilerinin plan öncesi otomatik
  görünür olması.

## Açık kararlar

Uygulamadan önce yalnız şu kararlar netleştirilmelidir:

1. Yerel Supabase her worktree için ayrı stack mi, paylaşılan tek stack + benzersiz
   test namespace'i mi kullanacak?
2. İlk kritik Flutter yolculuğu Chrome web mi, Windows desktop mı çalışacak?
3. Stateful preview testi tamamen yerelde mi, Supabase preview branch üzerinde mi
   koşacak? Ücretli branch seçeneği ancak açık bütçe onayıyla ele alınabilir.
4. Vercel'in `main` merge ile otomatik production yayını korunacak mı, ileride ayrı
   promote adımı mı istenecek?
5. İlk patch eval setine hangi 12 tarihsel vaka alınacak ve saklı kabul testlerini
   kim insan gözüyle onaylayacak?

Bu kararlar netleşmeden bütün katmanları tek PR'da uygulamak, çözülmek istenen
“görev büyüyünce plan sapması ve proje çökmesi” sorununu yeniden üretir.
