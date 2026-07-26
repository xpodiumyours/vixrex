# VixRex Agent Başlangıcı

Bu depoda çalışmaya başlayan her ajan, herhangi bir işlemden önce aşağıdaki sırayı uygular:

1. `VIXREX_RULES.md` dosyasını baştan sona oku.
2. Skill haritası olarak `.agents/skills/ask-matt/SKILL.md` dosyasını oku.
3. Göreve uyan skill veya skill’leri belirle.
4. Seçilen her skill’in `SKILL.md` dosyasını ve gerekli gördüğü bağlantılı dosyaları baştan sona oku.
5. Ardından ilgili kodu, `git status` çıktısını ve mevcut diff’i inceleyerek çalışmaya başla.

## Zorunlu ilişki

- `VIXREX_RULES.md`, VixRex’e özel ürün, güvenlik, kanıt ve canlı sistem sınırlarını tanımlar.
- `.agents/skills/`, görevin nasıl araştırılacağını, planlanacağını, uygulanacağını ve inceleneceğini tanımlar.
- Rules ve göreve uygun skill okunmadan kod, veritabanı, Git veya deploy işlemi başlatılmaz.
- Skill paketi kurulu diye bütün skill dosyaları her görevde yüklenmez; yalnızca `ask-matt` haritası ve göreve uygun olanlar okunur.
- Kullanıcıyla iletişim `VIXREX_RULES.md` içindeki Türkçe ve sade anlatım kurallarına uyar.
