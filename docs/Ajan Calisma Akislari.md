# VixRex ajan çalışma akışları

Bu sayfa, insanın göreceği tek skill rota tablosudur. Ajanların zorunlu başlangıcı `AGENTS.md`, makine tarafından kullanılan salt-okunur yönlendirici `.agents/skills/vixrex-router/SKILL.md` dosyasıdır.

## Her görevde ortak başlangıç

1. `VIXREX_RULES.md` okunur.
2. `vixrex-router` görev türünü ve gereken en küçük skill akışını seçer.
3. Seçilen skill dosyaları okunur.
4. Değişiklik işinde ilgili GitHub issue gövdesi, yorumları ve etiketleri okunur.
5. İlgili kod, `git status` ve mevcut diff incelenir.

Router yalnız rota seçer. Issue/yorum oluşturmaz, commit veya push yapmaz, PR açmaz, handoff yazmaz, canlı sisteme dokunmaz ve kullanıcı yetkisini genişletmez.

## Duruma göre rota

| Durum | Skill akışı | Çıkış ölçütü |
|---|---|---|
| Bir şey bozuk, sebebi belirsiz | `diagnosing-bugs` → `tdd` → `code-review` | Hatayı üreten tek kırmızı komut, en küçük düzeltme, yeşil kanıt |
| Yeni ve sınırları belli davranış | `tdd` → `code-review` | Önce kırmızı davranış testi, sonra en küçük production değişikliği |
| Küçük, issue’su hazır uygulama | `implement` | Issue kapsamı kırmızı-yeşil dilimlerle tamamlanır; review yapılır |
| Modül arayüzü veya sahipliği tasarlanacak | `codebase-design` → `tdd` → `code-review` | Küçük arayüz, gerçek test seam’i, açık sahip modül |
| Fikir var ama kararlar net değil | `grill-with-docs` → gerekirse `prototype` → `implement` | Kararlar bağlama yazılır; prototip kodu production sayılmaz |
| Çok oturumlu özellik | `grill-with-docs` → `to-spec` → `to-tickets` → her issue için `implement` | Bağımlılıkları belli küçük GitHub issue’ları |
| Yolu görünmeyen büyük çalışma | `wayfinder` → `to-spec` → `to-tickets` → `implement` | Önce karar haritası, sonra uygulanabilir spesifikasyon |
| Dışarıdan gelen ham bug/istek kuyruğu | `triage` | Uygun triage etiketi ve ajan/insan için net sonraki adım |
| Birincil kaynak araştırması | `research` → `grill-with-docs` | Kaynaklı araştırma karara girdi olur; tek başına uygulama değildir |
| Obsidian notu/bağlantısı | `obsidian-vault` | İnsan görünümü sade, wiki bağlantıları benzersiz |
| Oturum doldu veya ayrı oturuma geçilecek | `handoff` | Yetki verilmişse doğrulanabilir handoff belgesi |
| Hangi skill’in uyduğu hâlâ belirsiz | `ask-matt` | En küçük uygun akış seçilir; bütün skill’ler yüklenmez |

## Değişmez kapılar

- Commit önerisinden önce `code-review`.
- Sebebi belirsiz arızada tahminden önce `diagnosing-bugs` ve tek kırmızı komut.
- Yeni davranışta `tdd`: kırmızı kanıt görülmeden production kodu yok.
- Yeni modül arayüzünde `codebase-design`.
- Issue, skill ve kanıt alanları olmayan PR hazır sayılmaz.
- Migration gerekiyorsa yayın sırası her zaman veritabanı → kod; bu sayfa canlı sistem yetkisi vermez.

## Görev belleği

- Aktif plan ve durum: GitHub Issue.
- Kalıcı ürün/güvenlik kararları: `VIXREX_RULES.md`, `CONTEXT.md`, `docs/adr/`.
- Teknik depo haritası: `docs/agents/repository-guide.md`.
- Geçmiş planlar: açıkça adlandırılmış belgelerle `docs/arsiv/`.
- Kök `implementation_plan.md` ve aktif `docs/prompt*.md` dosyaları kullanılmaz.
