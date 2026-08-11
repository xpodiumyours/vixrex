# VixRex Agent Başlangıcı

Bu depoda çalışmaya başlayan her ajan, herhangi bir işlemden önce aşağıdaki sırayı uygular:

1. `VIXREX_RULES.md` muhafız kural dosyasını baştan sona oku.
2. Salt-okunur yönlendirici olarak `.agents/skills/vixrex-router/SKILL.md` dosyasını oku ve göreve uyan skill akışını belirle.
3. Seçilen her skill’in `SKILL.md` dosyasını ve zorunlu gördüğü bağlantılı dosyaları baştan sona oku. Rota belirsizse `.agents/skills/ask-matt/SKILL.md` haritasını kullan.
4. Değişiklik/geliştirme işinde ilgili GitHub issue’sunu gövdesi, yorumları ve etiketleriyle oku; plan kurmadan önce `python .github/scripts/vixrex_evidence.py --issue <n> --base origin/main` çalıştır.
5. Üretilen özetteki `contradicted` ve `unverified` bulguları açık tutarak ilgili kodu incele ve çalışmaya başla. Ayrıntı: `docs/agents/evidence-contract.md`.

## Zorunlu ilişki

- `VIXREX_RULES.md`, VixRex’e özel ürün, güvenlik, kanıt ve canlı sistem sınırlarını tanımlar.
- `.agents/skills/`, görevin nasıl araştırılacağını, planlanacağını, uygulanacağını ve inceleneceğini tanımlar.
- GitHub issue, uygulanacak işin hedefini, kapsamını, kararlarını ve ilerlemesini taşır. Mevcut repo ve çalışır durum aynı HEAD’e bağlı kanıt artefaktıyla doğrulanır. Kök dizinde `implementation_plan.md` tutulmaz.
- Rules, ilgili issue ve göreve uygun skill okunmadan kod, veritabanı, Git veya deploy işlemi başlatılmaz.
- Skill paketi kurulu diye bütün skill dosyaları her görevde yüklenmez; yalnız `vixrex-router`, seçtiği skill’ler ve gerektiğinde `ask-matt` okunur.
- `vixrex-router` ve diğer skill’ler yetki üretmez. Issue açma/düzenleme, commit, push, PR, handoff, canlı sistem veya başka yan etkiler yalnız kullanıcının verdiği yetki sınırında yapılır.
- Kullanıcıyla iletişim `VIXREX_RULES.md` içindeki Türkçe ve sade anlatım kurallarına uyar.

İnsan tarafından okunacak tek akış tablosu `docs/Ajan Calisma Akislari.md`, teknik depo haritası ise `docs/agents/repository-guide.md` dosyasıdır. Bu bilgiler model adaptörlerinde kopyalanmaz.

## Mimari büyüme yasağı

- 400 satırı veya 20 dışa açık üyeyi geçen controller/modüle yeni özellik ya da sorumluluk eklenmez; önce ayrı sahip modül ve küçük arayüz oluşturulur.
- Kodu mixin/extension'a taşımak tek başına refaktör sayılmaz; state, bağımlılık ve test seam'i gerçekten ayrılmalıdır.
- Yeni özellik başlamadan plan, özelliğin sahibi modülü ve arayüzünü adlandırır. Uygun sahip yoksa kodlama durur ve önce mimari ayrıştırma yapılır.
- Zorunlu hata düzeltmesi büyük modülde yapılabilir; fakat modülün dış arayüzü veya sorumluluk sayısı büyütülemez.

## Risk tabanlı skill çağrıları — Düşük Kredi Modu v1

Depodaki sürümlenen skill’ler `.agents/skills/` altındadır. Her görev `vixrex-router` ile başlar; yalnız görevin riskine gereken en küçük zincir yüklenir.

| Risk | Somut sinyal | Zorunlu akış |
|---|---|---|
| Hafif | Yalnız doküman/ADR, davranışsız metin veya rename, referanssızlığı kanıtlanmış ölü kod, yalnız değişen dosyada format, güvenli kullanılmayan sabit/SELECT temizliği | Değişiklik → `git diff` → hedefli doğrulama. TDD ve `code-review` zorunlu değildir. |
| Normal | Yeni kullanıcı davranışı veya mevcut davranış değişikliği | `tdd` → uygulama → `code-review` |
| Zor bug | Bir şey bozuk ve sebebi gerçekten bilinmiyor | `diagnosing-bugs` → `tdd` → uygulama → `code-review` |
| Yüksek risk | Migration/RLS/auth/security/sır/`service_role`, ödeme, toplu veri değişikliği veya silme, public veri görünürlüğü, CORE/publish, Flutter + Next.js ortak değişiklik, CI/kod üretim hattı, dependency/lockfile veya ajan güvenlik sözleşmesi | İlgili teşhis/tasarım + `tdd` + `code-review` ve etkilenen bütün güvenlik kapıları. Tasarruf uygulanmaz. |

### Sınıflandırma kuralları

- Etiket veya diff büyüklüğü değil, gerçek etki belirleyicidir. Herhangi bir yüksek risk sinyali varsa **yüksek risk kazanır**.
- “Ölü kod”, “format”, “rename” veya “SELECT temizliği” adı tek başına hafif kanıtı değildir. Runtime davranışı, veri sözleşmesi, generated çıktı, yetki veya iki yüzey etkileniyorsa risk yükseltilir.
- Bir zorunlu skill üst skill tarafından aynı diff için tamamlandıysa yeniden çağrılmaz. Aynı diff üzerinde aynı skill ikinci kez çalışmaz.
- Review sonrasında diff maddi olarak değişirse ikinci review yalnız yüksek riskte veya ciddi review bulgusunda yapılır; diğer işlerde hedefli doğrulama ve CI kullanılır.
- Skill çağrılamıyorsa sebep raporda `skill çağrılamadı: …` biçiminde açıkça yazılır.

### Oturum ve PR sınırı

- Bir oturum yalnız bir issue/PR üzerinde çalışır. Yeni issue veya PR temiz oturumla başlar.
- Aynı PR’ın düzeltmeleri aynı branch üzerinde sürer. Context dolarsa aynı PR için temiz oturum açılabilir; yeni doğrulama PR’ı açılmaz.
- CI kırılırsa mevcut PR branch’i düzeltilir ve CI yeniden çalışır.

### Test bütçesi

1. Çalışırken yalnız ilgili küçük test çalıştırılır.
2. İş bitince etkilenen yüzeyin typecheck/lint/analyze kapısı çalıştırılır.
3. PR hazırlanırken yalnız etkilenen yüzeyin full suite’i en fazla bir kez çalıştırılır.
4. Full suite sonrasında kod değişirse yalnız etkilenen testler tekrar çalıştırılır; yüksek risk veya ortak altyapı değişikliği full suite tekrarını gerekçelendirebilir.
5. CI bağımsız son kontroldür. Yeşil komut yalnız “emin olmak” için tekrarlanmaz.
6. Format komutu bütün repoya değil yalnız görevde değişen dosyalara uygulanır.

**Neden bu kural var:** 2026-08-05’te çalıştırılmayan kontroller beş gerçek hatanın canlıya kadar gitmesine izin verdi. Koruma bu nedenle riskli işlerde aynen kalır; düşük riskli işlerde ise aynı pahalı zincirin koşulsuz tekrarı kaldırılır.

## Dal ve PR kuralları

Bu kurallar 2026-08-04'te, 13 açık PR'ın 5'inin ölü çıkması ve birleştirilmiş bir dalda çalışmaya devam edilmesi yüzünden yazıldı.

- **Squash ile birleştirilen dalda çalışmaya devam edilmez.** PR birleştikten sonra iş biterse `main`'den yeni dal açılır. Aksi hâlde aynı içerik iki farklı commit olarak görünür ve sonraki PR çakışır.
- **Yeni PR açmadan önce aynı iş için açık PR var mı bakılır** (`gh pr list --state open`). Aynı işin ikinci PR'ı açılmaz.
- **Bir dal PR'sız bırakılmaz.** PR'ı olmayan dalın `main`'e gidecek yolu yoktur; iş orada sessizce ölür.
- **Bir aydan eski açık PR ya birleştirilir ya kapatılır.** Kod hızla değişiyor; eski PR'ın dosyaları artık var olmayabilir. Karar vermeden önce `gh pr diff <n> --name-only` ile dosyaların hâlâ mevcut olup olmadığı kontrol edilir.
- **PR kapatılırken dal silinmez** (`--delete-branch` kullanılmaz) ve kapatma sebebi yoruma yazılır.

## Yayına çıkış sırası

Kullanıcı bu adımları ezberlemek zorunda değildir; ajan sırayı uygular ve her adımda ne yaptığını söyler.

**Değişmez sıra: önce veritabanı, sonra kod.**

Yayına çıkarken iki ayrı şey gider ve aynı anda gitmezler:

1. **Kod** — `main`'e merge edilince Vercel otomatik yayınlar. **Yani merge etmek yayınlamaktır.**
2. **Migration** — otomatik gitmez, ayrıca uygulanır.

Kod önce giderse site kırılır: kod olmayan bir kolonu bekler. Migration önce giderse yeni tablolar bir süre boş durur, kimse fark etmez. Bu yüzden sıra tersine çevrilmez.

- Merge öncesi, o kodun beklediği tüm migration'ların canlıya uygulanmış olduğu **kontrol edilir**. Uygulanmamışsa merge durdurulur ve kullanıcıya söylenir.
- Migration geri alınamaz kabul edilir. Kod `git revert` ile geri alınabilir; silinen kolon geri gelmez. `DROP`, tür değiştirme ve toplu `UPDATE/DELETE` içeren migration için önce yedek ve geri dönüş SQL'i hazırlanır.
- **İki ayrı Vercel projesi vardır:** `vixrex-app` (Flutter paneli) ve `vixrex-public` (müşteri vitrini). Birinin başarılı olması diğeri hakkında bilgi vermez; ikisi ayrı ayrı doğrulanır.
- Deploy'un "başarılı" görünmesi sitenin çalıştığı anlamına gelmez. Yayın sonrası gerçek bir vitrin açılıp göz ile doğrulanır; doğrulanmadıysa "canlıda doğrulanmadı" denir.
- Bu depoda `main` production dalıdır. Feature dalı preview içindir.

## Agent skills

### Issue tracker

Issues live as GitHub issues (repo `xpodiumyours/vixrex`), operated with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default triage vocabulary is used (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
