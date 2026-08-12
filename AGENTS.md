# VixRex Agent Başlangıcı

Bu depoda çalışmaya başlamadan önce:

1. `VIXREX_RULES.md` dosyasını baştan sona oku.
2. İlgili kodu, `git status` çıktısını ve mevcut diff'i incele.
3. Kullanıcının açık kapsamı dışına çıkma; issue, PR, skill veya plan belgesi üretmeyi kendiliğinden yeni işe dönüştürme.

## Kaynaklar

- `VIXREX_RULES.md`: ürün, güvenlik, kanıt ve canlı sistem sınırları.
- `docs/agents/repository-guide.md`: teknik depo haritası ve yüzeye özel komutlar.
- `CONTEXT.md` ve `docs/adr/`: kalıcı ürün ve mimari kararlar.
- GitHub issue: yalnız kullanıcı bir issue'yu adlandırdığında veya mevcut iş açıkça ona bağlıysa kapsam kaynağıdır.

Skill'ler isteğe bağlı çalışma yardımcılarıdır; kullanıcı yetkisini genişletmez ve her görevde zorunlu bir zincir oluşturmaz.

## Skill seçimi

İş net biçimde bir kalıba uyuyorsa doğaçlama yapılmaz, uyan skill çalıştırılır:

- "Bir şey bozuldu / çalışmıyor / hata veriyor" → `diagnosing-bugs`. Kırmızıya düşen sıkı bir kontrol kurulmadan koda bakıp teori üretilmez — bu skill'in önlediği tam olarak budur.
- Çok adımlı yeni özellik/fikir → `grill-with-docs` → (gerekirse `to-spec`/`to-tickets`) → `implement` (içeride `tdd` + `code-review` çalıştırır).
- Mimari inceleme veya modül tasarımı → `codebase-design` / `improve-codebase-architecture`.
- Hangi skill uyduğundan emin değilsen `ask-matt`'ın haritasına bak.

Bu bir zincir DEĞİLDİR: issue bağlama, kanıt scripti veya ek onay gerektirmez (2026-08-11 tarihli #123'te kaldırılan bürokrasi geri gelmez) — yalnızca doğru yönteme girmeyi sağlar. Basit, tek adımlı okuma/araştırma/durum sorularında skill gerekmez.

## Mimari büyüme yasağı

- 400 satırı veya 20 dışa açık üyeyi geçen controller/modüle yeni sorumluluk eklenmez; önce ayrı sahip modül ve küçük arayüz oluşturulur.
- Mixin/extension'a taşımak tek başına ayrıştırma değildir; state, bağımlılık ve test seam'i gerçekten ayrılmalıdır.
- Yeni özellik planı sahip modülü ve arayüzünü adlandırır. Uygun sahip yoksa önce mimari ayrıştırma yapılır.
- Zorunlu hata düzeltmesi büyük modülde yapılabilir; dış arayüzü veya sorumluluk sayısı büyütülemez.

## Git, PR ve yayın değişmezleri

- Kullanıcı değişiklikleri korunur; force push ve `git reset --hard` kullanılmaz.
- Squash ile birleşmiş dalda devam edilmez. Aynı iş için ikinci PR veya yalnız CI doğrulama PR'ı açılmaz.
- PR'sız dal bırakılmaz; CI düzeltmesi mevcut PR branch'inde yapılır.
- `main` production dalıdır; merge etmek iki Vercel projesinin ilgili olanında yayını tetikleyebilir.
- Force push, `git reset --hard`, `git clean -f(d)`, `git branch -D`, `git checkout .`/`restore .` bu depoda bir Claude Code hook'u tarafından teknik olarak engellenir (`.claude/hooks/block-dangerous-git.sh`) — kural metne değil, koda bağlı (2026-08-12 eklendi).
- Bir PR 12 dosya veya 600 satırdan büyükse CI (`Kapsam kontrolü`, `.github/scripts/verify_pr_scope.py`) kırmızıya düşer. Kullanıcıdan gerçek onay alındıysa PR açıklamasına `Kapsam-Onay: <kısa özet>` satırı eklenir; yoksa iş küçük PR'lara bölünür. Bu, kullanıcının kod okumadan bir ajanın kapsam dışına çıktığını fark edebilmesi için var (2026-08-12 PR #134 dersi).
- Migration gerekiyorsa sıra veritabanı → kod. Merge öncesi gerekli migration'ın canlı durumu doğrulanır.
- `vixrex-app` ve `vixrex-public` ayrı projelerdir; biri diğerini doğrulamaz.
- Canlı sonuç commit + proje + URL ile doğrulanmadıysa “canlıda doğrulanmadı” denir.

## Doğrulama bütçesi

- Geliştirme sırasında yalnız ilgili küçük kontrolü çalıştır.
- İş bitince etkilenen yüzeyin analiz/lint/typecheck kapısını çalıştır.
- Aynı değişiklik için başarılı tam test paketini gereksiz yere tekrarlama.
- Push, PR, merge, deploy ve canlı migration yalnız kullanıcının açık isteğiyle yapılır.
