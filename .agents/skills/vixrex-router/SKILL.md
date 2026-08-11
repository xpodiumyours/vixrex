---
name: vixrex-router
description: VixRex deposundaki her görevin başında isteği ve gerçek etkiyi sınıflandırır; hafif, normal, zor bug veya yüksek risk için gereken en küçük skill zincirini seçer. Hata, davranış değişikliği, planlama, araştırma, Obsidian veya review isteğinde otomatik kullan; salt-okunur yönlendirme yapar ve kullanıcı yetkisini genişletmez.
---

# VixRex skill yönlendiricisi

Bu skill yalnız rota seçer; görevi uygulamaz.

## Girdiler

- Kullanıcının son isteği ve açık yetki sınırı.
- `AGENTS.md` başlangıç ve düşük kredi sözleşmesi.
- İnsan için tek rota kaynağı: `docs/Ajan Calisma Akislari.md`.
- Gerekirse ayrıntılı upstream harita: `.agents/skills/ask-matt/SKILL.md`.

## Yönlendirme

1. `docs/Ajan Calisma Akislari.md` dosyasını baştan sona oku.
2. Salt-okunur/özel bir istekse tablodaki araştırma, triage, Obsidian, handoff veya yalnız review rotasını seç.
3. Değişiklik işini gerçek etkisine göre sınıflandır:
   - **Hafif:** Yalnız doküman/ADR, davranışsız metin/rename, referanssızlığı kanıtlanmış ölü kod, değişen dosyada format veya runtime/veri sözleşmesine dokunmayan temizlik.
   - **Normal:** Yeni kullanıcı davranışı veya mevcut davranış değişikliği.
   - **Zor bug:** Bir şey bozuk ve sebebi gerçekten bilinmiyor.
   - **Yüksek risk:** Migration/RLS/auth/security/sır/`service_role`, ödeme, toplu veri değişikliği/silme, public veri görünürlüğü, CORE/publish, Flutter + Next.js ortak değişiklik, CI/kod üretim hattı, dependency/lockfile veya ajan güvenlik sözleşmesi.
4. Birden fazla sınıf eşleşirse **yüksek risk kazanır**; işin adı veya diff küçüklüğü riski düşürmez.
5. Tablodaki en küçük yeterli skill zincirini seç. Aynı anda bütün skill’leri yükleme.
6. Aynı diff için daha önce tamamlanan skill’leri rotadan çıkar. Üst skill’in çalıştırdığı `tdd` veya `code-review` tamamlanmış sayılır; aynı diff üzerinde aynı skill ikinci kez çalışmaz.
7. Review sonrası maddi diff değişikliğinde ikinci review yalnız yüksek risk veya ciddi bulgu varsa seçilir.
8. Seçilen her adım için `.agents/skills/<ad>/SKILL.md` bulunduğunu doğrula. Eksik adımı uydurma; rota belirsizse `ask-matt` oku ve eksikliği raporla.
9. Rotayı bildir, sonra seçilen skill talimatlarını uygula:

```text
Risk: <hafif / normal / zor bug / yüksek risk / salt-okunur>
Rota: vixrex-router → <skill> → <skill>
Gerekçe: <istekteki somut etki>
Yetki: <salt-okunur / kullanıcının açık değişiklik sınırı>
```

Hafif işte ek skill yoksa `Rota: vixrex-router` yaz.

## Sert güvenlik sınırı

- Bu skill dosya, issue, yorum veya handoff oluşturmaz/değiştirmez.
- Git branch, commit, push, PR, merge, deploy, migration veya canlı sistem işlemi başlatmaz.
- Bir alt skill’in böyle bir işlem tarif etmesi kullanıcı yetkisinin yerine geçmez.
- Kullanıcı yalnız inceleme/teşhis istemişse rota da salt-okunur kalır.
- Bir oturum yalnız bir issue/PR üzerinde çalışır; yeni issue/PR temiz oturumla başlar.
- Aynı PR’ın CI düzeltmesi mevcut branch üzerinde yapılır; doğrulama için ikinci PR açılmaz.
