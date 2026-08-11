# VixRex Agent Başlangıcı

Bu depoda her ajan, işlemden önce şu sırayı uygular:

1. `VIXREX_RULES.md` dosyasını baştan sona oku.
2. Salt-okunur yönlendirici `.agents/skills/vixrex-router/SKILL.md` dosyasını oku.
3. Router'ın seçtiği skill dosyalarını ve zorunlu bağlantılarını oku; rota belirsizse `.agents/skills/ask-matt/SKILL.md` kullan.
4. Değişiklik işinde ilgili GitHub issue'sunu gövde, yorum ve etiketleriyle oku; plan öncesi `python .github/scripts/vixrex_evidence.py --issue <n> --base origin/main` çalıştır.
5. `contradicted` ve `unverified` bulguları açık tutarak ilgili kodu, `git status` ve mevcut diff'i incele.

## Tek kaynak haritası

- `VIXREX_RULES.md`: VixRex'e özel ürün, güvenlik, kanıt ve canlı sistem sınırları.
- `docs/Ajan Calisma Akislari.md`: risk, skill zinciri, tekrar, oturum/PR ve test bütçesinin **tek sözleşme kaynağı**.
- `docs/agents/repository-guide.md`: teknik depo haritası ve yüzeye özel komutlar.
- GitHub issue: hedef, kapsam, karar ve ilerleme. Kök `implementation_plan.md` kullanılmaz.
- `.agents/skills/`: görevin nasıl yürütüleceği; yetki kaynağı değildir.

Router ve skill'ler kullanıcı yetkisini genişletmez. Issue, dosya, Git, PR, migration, deploy veya canlı sistem yan etkileri yalnız kullanıcının açık yetki sınırında yapılır. Model adaptörleri bu sözleşmeleri kopyalamaz; yalnız `AGENTS.md` dosyasına yönlendirir.

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
- Migration gerekiyorsa sıra veritabanı → kod. Merge öncesi gerekli migration'ın canlı durumu doğrulanır.
- `vixrex-app` ve `vixrex-public` ayrı projelerdir; biri diğerini doğrulamaz.
- Canlı sonuç commit + proje + URL ile doğrulanmadıysa “canlıda doğrulanmadı” denir.

## Agent skills

GitHub issue kullanımı: `docs/agents/issue-tracker.md`.
Triage etiketleri: `docs/agents/triage-labels.md`.
Kalıcı bağlam: `CONTEXT.md` ve `docs/adr/`.
Kanıt sözleşmesi: `docs/agents/evidence-contract.md`.
