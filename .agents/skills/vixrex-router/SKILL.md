---
name: vixrex-router
description: VixRex deposundaki her görevin başında görev türünü sınıflandırır ve docs/Ajan Calisma Akislari.md içinden gereken en küçük skill zincirini seçer. Hata, yeni davranış, planlama, araştırma, Obsidian veya review isteğinde otomatik kullan; yalnız salt-okunur yönlendirme yapar ve kullanıcı yetkisini genişletmez.
---

# VixRex skill yönlendiricisi

Bu skill’in tek sorumluluğu **rota seçmek**tir. Görevi uygulamaz.

## Girdiler

- Kullanıcının son isteği ve açık yetki sınırı.
- `AGENTS.md` başlangıç sözleşmesi.
- İnsan için tek rota kaynağı: `docs/Ajan Calisma Akislari.md`.
- Gerekirse ayrıntılı upstream harita: `.agents/skills/ask-matt/SKILL.md`.

## Yönlendirme

1. `docs/Ajan Calisma Akislari.md` dosyasını baştan sona oku.
2. İsteğin birincil durumunu belirle: sebebi belirsiz arıza, yeni davranış, hazır issue uygulaması, arayüz/modül tasarımı, belirsiz fikir, çok oturumlu çalışma, büyük karar haritası, triage, araştırma, Obsidian, handoff veya yalnız review.
3. Tablodaki **en küçük yeterli** skill akışını seç. Aynı anda bütün skill’leri yükleme.
4. Seçilen her adım için `.agents/skills/<ad>/SKILL.md` bulunduğunu doğrula. Bulunmayan adımı uydurma; rota belirsizse `ask-matt` oku ve eksikliği raporla.
5. Aşağıdaki kısa biçimde rotayı kullanıcıya bildir, sonra seçilen skill talimatlarını uygula:

```text
Rota: vixrex-router → <skill> → <skill>
Gerekçe: <istekteki somut sinyal>
Yetki: <salt-okunur / kullanıcının açıkça verdiği değişiklik sınırı>
```

## Sert güvenlik sınırı

- Bu skill dosya, issue, yorum veya handoff oluşturmaz/değiştirmez.
- Git branch, commit, push, PR, merge, deploy, migration veya canlı sistem işlemi başlatmaz.
- Bir alt skill’in böyle bir işlem tarif etmesi kullanıcı yetkisinin yerine geçmez.
- Kullanıcı yalnız inceleme/teşhis istemişse rota da salt-okunur kalır.
- Yeni davranış uygulanacaksa `tdd`; sebebi belirsiz arızada `diagnosing-bugs`; commit önerisinden önce `code-review` atlanmaz.
