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

## Zorunlu skill çağrıları

Depodaki sürümlenen skill’ler `.agents/skills/` altındadır. Codex, OpenCode, Gemini ve Claude Code bu kaynağı kullanır. **Sorun erişim değil, çağrılmaması olmuştur** — 2026-08-05'e kadar hiçbir ajan bunları kullanmadı ve önlenebilir hatalar canlıya kadar gitti.

Aşağıdaki durumlarda ilgili skill **çağrılır**, atlanmaz:

| Durum | Zorunlu skill |
|---|---|
| Commit önerilmeden önce | `code-review` — değişikliği standart ve istek eksenlerinde inceler |
| Bir şey bozuk, sebebi belirsiz | `diagnosing-bugs` — tahmin etmeden önce hatayı üreten tek komut ister |
| Yeni davranış yazılacak | `tdd` — önce kırmızı test, sonra kod |
| Bir modülün arayüzü tasarlanacak | `codebase-design` |
| Hangi skill'in uyduğu belirsiz | `vixrex-router`, gerekirse `ask-matt` — skill haritası |

Skill çağrılmadan commit önerilmez. Çağrılamıyorsa sebebi raporda yazılır ("skill çağrılamadı: …"), sessizce atlanmaz.

**Neden bu kural var:** 2026-08-05'te tek bir oturumda beş gerçek hata çıktı — sahip paneli hiç açılmıyordu, `edit_token` tarayıcıya sızıyordu, migration hiç uygulanamıyordu, iki test hatayı doğruymuş gibi kilitliyordu, React anahtarları çakışıyordu. Hiçbiri kod okunarak bulunamadı; hepsi çalıştırılınca çıktı. `code-review` ve `diagnosing-bugs` bunların çoğunu daha erken yakalardı.

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
