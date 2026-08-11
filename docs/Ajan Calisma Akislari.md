# VixRex ajan çalışma akışları

Bu sayfa risk sınıfları, skill zincirleri, tekrar, oturum/PR kuralları ve test bütçesinin tek sözleşme kaynağıdır. Ajanların zorunlu başlangıcı `AGENTS.md`, salt-okunur yönlendirici `.agents/skills/vixrex-router/SKILL.md` dosyasıdır.

## Her görevde ortak başlangıç

1. `VIXREX_RULES.md` okunur.
2. `vixrex-router` görev türünü, riskini ve gereken en küçük skill akışını seçer.
3. Seçilen skill dosyaları okunur.
4. Değişiklik işinde ilgili GitHub issue gövdesi, yorumları ve etiketleri okunur.
5. İlgili kod, `git status` ve mevcut diff incelenir.

Router yalnız rota seçer. Issue/yorum oluşturmaz, commit veya push yapmaz, PR açmaz, handoff yazmaz, canlı sisteme dokunmaz ve kullanıcı yetkisini genişletmez.

## Değişiklik riskine göre rota

| Risk | Durum | Skill akışı | Çıkış ölçütü |
|---|---|---|---|
| Hafif | Yalnız doküman/ADR, davranışsız metin/rename, referanssız ölü kod, değişen dosyada format veya runtime/veri sözleşmesine dokunmayan temizlik | `vixrex-router` | Diff + hedefli küçük doğrulama |
| Normal | Yeni kullanıcı davranışı veya mevcut davranış değişikliği | `tdd` → `code-review` | Önce kırmızı davranış testi, en küçük production değişikliği, tek review |
| Zor bug | Bir şey bozuk ve sebebi gerçekten bilinmiyor | `diagnosing-bugs` → `tdd` → `code-review` | Hatayı üreten tek kırmızı komut, kök neden, en küçük düzeltme |
| Yüksek risk | Migration/RLS/auth/security/sır, ödeme, toplu veri, public görünürlük, CORE/publish, Flutter + Next.js, CI/kod üretimi, dependency/lockfile veya ajan güvenlik sözleşmesi | Gerekiyorsa `diagnosing-bugs` → `tdd` → `code-review` | Etkilenen tüm güvenlik kapıları, geri dönüş planı ve bağımsız CI |

Herhangi bir yüksek risk sinyalinde **yüksek risk kazanır**. “Format”, “rename”, “ölü kod” veya küçük diff etiketi tek başına hafif risk kanıtı değildir.

Kullanıcı `implement` skill’ini açıkça çağırırsa skill bu risk rotasını uygular; üst skill’in tamamladığı `tdd` veya `code-review` aynı diff için yeniden çağrılmaz.

## Özel ve salt-okunur rotalar

| Durum | Skill akışı | Çıkış ölçütü |
|---|---|---|
| Modül arayüzü veya sahipliği tasarlanacak | `codebase-design` → risk rotası | Küçük arayüz, gerçek test seam’i, açık sahip modül |
| Fikir var ama kararlar net değil | `grill-with-docs` → gerekirse `prototype` | Kararlar bağlama yazılır; prototip production sayılmaz |
| Çok oturumlu özellik | `grill-with-docs` → `to-spec` → `to-tickets` | Bağımlılıkları belli küçük GitHub issue’ları |
| Yolu görünmeyen büyük çalışma | `wayfinder` → `to-spec` → `to-tickets` | Önce karar haritası, sonra uygulanabilir spesifikasyon |
| Dışarıdan gelen ham bug/istek kuyruğu | `triage` | Uygun triage etiketi ve net sonraki adım |
| Birincil kaynak araştırması | `research` → `grill-with-docs` | Kaynaklı araştırma karara girdi olur; uygulama değildir |
| Obsidian notu/bağlantısı | `obsidian-vault` | İnsan görünümü sade, wiki bağlantıları benzersiz |
| Oturum doldu veya aynı PR temiz oturumda sürecek | `handoff` | Yetki verilmişse doğrulanabilir handoff |
| Hangi skill’in uyduğu hâlâ belirsiz | `ask-matt` | En küçük uygun akış seçilir |
| Yalnız review istendi | `code-review` | Standards ve spec bulguları ayrı raporlanır |

## Tekrar, oturum ve PR sözleşmesi

- Aynı diff üzerinde aynı skill ikinci kez çalışmaz. Üst skill’in çalıştırdığı zorunlu skill tamamlanmış sayılır.
- Review sonrasında diff maddi değişirse ikinci review yalnız yüksek risk veya ciddi bulguda yapılır.
- Bir oturum yalnız bir issue/PR üzerinde çalışır. Yeni issue/PR temiz oturumla başlar.
- Aynı PR’ın düzeltmeleri aynı branch’te sürer. Context dolarsa aynı PR için temiz oturum açılabilir.
- CI doğrulamak için ikinci PR açılmaz; mevcut PR branch’i düzeltilir.

## Test bütçesi

| Aşama | Çalıştırılacak kontrol |
|---|---|
| Geliştirme sırasında | Yalnız ilgili küçük test |
| İş bitince | Etkilenen yüzeyin typecheck/lint/analyze kapısı |
| PR hazırlanırken | Etkilenen yüzeyin full suite’i en fazla bir kez |
| CI | Bağımsız son kontrol |

Full suite yeşilken aynı diff için tekrar çalıştırılmaz. Sonrasında kod değişirse yalnız ilgili testler yenilenir; yüksek risk veya ortak altyapı değişikliği full suite tekrarını gerekçelendirebilir. Format yalnız değişen dosyalara uygulanır.

## Değişmez güvenlik kapıları

- Sebebi belirsiz arızada tahminden önce `diagnosing-bugs` ve tek kırmızı komut.
- Yeni davranışta `tdd`: kırmızı kanıt görülmeden production kodu yok.
- Yeni modül arayüzünde `codebase-design`.
- Yüksek riskte `code-review` ve etkilenen güvenlik kapıları.
- Issue, risk/skill akışı ve kanıt alanları olmayan PR hazır sayılmaz.
- Migration gerekiyorsa yayın sırası her zaman veritabanı → kod; bu sayfa canlı sistem yetkisi vermez.

## Görev belleği

- Aktif plan ve durum: GitHub Issue.
- Kalıcı ürün/güvenlik kararları: `VIXREX_RULES.md`, `CONTEXT.md`, `docs/adr/`.
- Teknik depo haritası: `docs/agents/repository-guide.md`.
- Geçmiş planlar: açıkça adlandırılmış belgelerle `docs/arsiv/`.
- Kök `implementation_plan.md` ve aktif `docs/prompt*.md` dosyaları kullanılmaz.
