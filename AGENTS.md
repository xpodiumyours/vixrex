# VixRex Agent Başlangıcı

## HIZLI GÖREV YOLU — ÖNCELİKLİ KURAL

Aşağıdaki isteklerde tam depo incelemesi YAPMA:

- "son commit'i incele"
- "ne değişti"
- "diff'e bak"
- "bu commit ne yaptı"
- "mevcut durumu söyle"
- "şu dosyayı kontrol et"
- küçük UI/CSS düzeltmesi incelemesi

Bu görevlerde çalışma sırası:

1. Önce yalnız:
   - `git status --short`
   - `git show --stat --oneline HEAD`
   - `git diff HEAD^ HEAD -- <değişen dosyalar>`

2. Sadece değişen dosyaları ve doğrudan bağlı kodu oku.

3. `VIXREX_RULES.md` ve `CONTEXT.md` her görevde baştan sona tekrar okunmaz.
   Yalnız görev ürün/mimari/güvenlik kuralına dokunuyorsa ilgili bölüm okunur.

4. Bu görevlerde varsayılan olarak YASAK:
   - standards review
   - spec review
   - code-review skill
   - ask-matt
   - alt ajan/subagent
   - issue/PR geçmişi taraması
   - bütün repo taraması
   - plan belgesi analizi
   - GitHub Actions araştırması

5. Test/lint/build varsayılan olarak ÇALIŞTIRILMAZ.

   Sadece:
   - kullanıcı açıkça isterse,
   - değişiklik derleme/runtime riski taşıyorsa,
   - bulunan somut bir hatayı doğrulamak gerekiyorsa

   ilgili EN KÜÇÜK test çalıştırılır.

6. Aynı başarılı test/build ikinci kez çalıştırılmaz.

7. İnceleme çıktısı doğrudan şu formatta verilir:

   DEĞİŞTİ:
   - dosya
   - yapılan değişiklik

   BAŞARDIĞI:
   - somut sonuç

   EKSİK/HATALI:
   - yalnız doğrulanmış bulgular

   SONRAKİ AKSİYON:
   - gerekiyorsa tek net işlem

8. Basit commit/diff incelemesinde amaç doğruluk + hızdır.
   Araştırma işini kendi kendine büyütme.
Bu depoda çalışmaya başlamadan önce:

1. Yeni çalışma oturumunda veya görev ilgili kurallara dokunuyorsa
   `VIXREX_RULES.md` dosyasının gerekli bölümünü oku.
2. `CONTEXT.md` yalnız ürün/mimari karar gerektiren görevlerde okunur.
   Basit commit/diff/UI incelemesinde tekrar okunmaz.
3. İlgili kodu, `git status` çıktısını ve mevcut diff'i incele.
4. Kullanıcının açık kapsamı dışına çıkma; issue, PR, skill veya plan belgesi üretmeyi kendiliğinden yeni işe dönüştürme.

## Kaynaklar

- `VIXREX_RULES.md`: ürün, güvenlik, kanıt ve canlı sistem sınırları.
- `docs/agents/repository-guide.md`: teknik depo haritası ve yüzeye özel komutlar.
- `docs/agents/store-editor-controller-parcalama.md`: devam eden controller parçalama işinin durumu — bu işe dokunmadan önce oku.
- `docs/adr/`: ADR'ler — kalıcı ürün ve mimari kararlar (0001 omurga, 0002 asistan, 0003 vault kuralı).
- GitHub issue: yalnız kullanıcı bir issue'yu adlandırdığında veya mevcut iş açıkça ona bağlıysa kapsam kaynağıdır.

Skill'ler isteğe bağlı çalışma yardımcılarıdır; kullanıcı yetkisini genişletmez ve her görevde zorunlu bir zincir oluşturmaz.

## Skill seçimi

İş net biçimde bir kalıba uyuyorsa doğaçlama yapılmaz, uyan skill çalıştırılır:

- "Bir şey bozuldu / çalışmıyor / hata veriyor" → `diagnosing-bugs`. Kırmızıya düşen sıkı bir kontrol kurulmadan koda bakıp teori üretilmez — bu skill'in önlediği tam olarak budur.
- Çok adımlı yeni özellik/fikir → `grill-with-docs` → (gerekirse `to-spec`/`to-tickets`) → `implement` (içeride `tdd` + `code-review` çalıştırır).
- Mimari inceleme veya modül tasarımı → `codebase-design` / `improve-codebase-architecture`.
- Görsel/tasarım işi (logo, banner, UI şekillendirme, sunum) → `ui-ux-pro-max` / `design` / `brand` / `slides` — harita `ask-matt`'ta "Design & UI (gerektiğinde)" grubunda.
- Hangi skill uyduğundan emin değilsen `ask-matt`'ın haritasına bak.

## Skill yönetimi

- KANONİK kaynak: `.agents/skills/` — yeni skill ekleme/düzenleme YALNIZCA burada yapılır (Codex, Cursor, Freebuff buradan okur).
- Claude Code yalnızca `.claude/skills/` okur → `bash tool/sync_skills` ile ayna güncellenir; ayna değişiklikleri de commit edilir.
- `skills-lock.json` her skill'in kaydını tutar (hash dahil) — yeni skill eklendikten sonra güncellenir.

Bu bir zincir DEĞİLDİR: issue bağlama, kanıt scripti veya ek onay gerektirmez (2026-08-11 tarihli #123'te kaldırılan bürokrasi geri gelmez) — yalnızca doğru yönteme girmeyi sağlar. Basit, tek adımlı okuma/araştırma/durum sorularında skill gerekmez.

## Mimari büyüme yasağı

- 400 satırı veya 20 dışa açık üyeyi geçen controller/modüle yeni sorumluluk eklenmez; önce ayrı sahip modül ve küçük arayüz oluşturulur.
- Bu kural 2026-08 içinde `store_editor_controller.dart`'ın 1388 satıra çıkmasını engelleyemedi çünkü yalnız metindi, hiçbir yerde otomatik kontrol edilmiyordu (9 fazlık parçalamayla 1072'ye indirildi, bkz. `docs/agents/store-editor-controller-parcalama.md`). Artık `.github/dosya_boyutu_ratchet.json`'da izlenen dosyalar için CI (`Dosya büyüklüğü rateti`, `.github/scripts/verify_dosya_boyutu_ratchet.py`) mevcut satır sayısını bir tavan olarak kilitler — dosya bu PR sonrası tavanı aşarsa kırmızıya düşer. Yeni özellik bu dosyaya değil, yeni bir servise yazılır; gerçekten büyütmek gerekiyorsa tavan aynı PR'da bilinçli olarak yükseltilir (nedeni JSON'daki `not` alanına yazılır).
- Mixin/extension'a taşımak tek başına ayrıştırma değildir; state, bağımlılık ve test seam'i gerçekten ayrılmalıdır.
- Yeni özellik planı sahip modülü ve arayüzünü adlandırır. Uygun sahip yoksa önce mimari ayrıştırma yapılır.
- Zorunlu hata düzeltmesi büyük modülde yapılabilir; dış arayüzü veya sorumluluk sayısı büyütülemez.

## Git, PR ve yayın değişmezleri

- Kullanıcı değişiklikleri korunur; force push ve `git reset --hard` kullanılmaz.
- Squash ile birleşmiş dalda devam edilmez. Aynı iş için ikinci PR veya yalnız CI doğrulama PR'ı açılmaz.
- PR'sız dal bırakılmaz; CI düzeltmesi mevcut PR branch'inde yapılır.
- Yeni bir PR açılırken base'in `main` olduğu açıkça doğrulanır (`gh pr create --base main`). Bir PR'ı bilerek başka bir PR'ın üzerine zincirlemek gerekiyorsa bu açıkça belirtilir ve zincirin en ucu main'e ulaşana kadar iş bitmiş sayılmaz — ara PR'ların "merged" görünmesi yeterli değildir; PR listesi "merged mi" gösterir, "nereye" göstermez (2026-08-15 dersi: #170→#171→#172→#173 birbirinin üzerine zincirlendi, hiçbiri main'e ulaşmadı).
- `main` production dalıdır; merge etmek iki Vercel projesinin ilgili olanında yayını tetikleyebilir.
- Force push, `git reset --hard`, `git clean -f(d)`, `git branch -D`, `git checkout .`/`restore .` bu depoda bir Claude Code hook'u tarafından teknik olarak engellenir (`.claude/hooks/block-dangerous-git.sh`) — kural metne değil, koda bağlı (2026-08-12 eklendi).
- Bir PR 12 dosya veya 600 satırdan büyükse CI (`Kapsam kontrolü`, `.github/scripts/verify_pr_scope.py`) kırmızıya düşer. Kullanıcıdan gerçek onay alındıysa PR açıklamasına `Kapsam-Onay: <kısa özet>` satırı eklenir; yoksa iş küçük PR'lara bölünür. Bu, kullanıcının kod okumadan bir ajanın kapsam dışına çıktığını fark edebilmesi için var (2026-08-12 PR #134 dersi).
- Migration gerekiyorsa sıra veritabanı → kod. Merge öncesi gerekli migration'ın canlı durumu doğrulanır.
- `vixrex-app` ve `vixrex-public` ayrı projelerdir; biri diğerini doğrulamaz.
- Canlı sonuç commit + proje + URL ile doğrulanmadıysa “canlıda doğrulanmadı” denir.

## Doğrulama bütçesi

- Salt inceleme/durum/commit-diff görevlerinde doğrulama bütçesi varsayılan olarak 0 test + 0 build'dir.
- Geliştirme sırasında yalnız ilgili küçük kontrolü çalıştır.
- İş bitince etkilenen yüzeyin analiz/lint/typecheck kapısını çalıştır.
- Aynı değişiklik için başarılı tam test paketini gereksiz yere tekrarlama.
- Push, PR, merge, deploy ve canlı migration yalnız kullanıcının açık isteğiyle yapılır.
