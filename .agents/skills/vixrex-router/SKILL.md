---
name: vixrex-router
description: VixRex deposundaki her görevin başında isteği ve gerçek etkiyi sınıflandırır, gereken en küçük skill zincirini seçer. Hata, davranış değişikliği, planlama, araştırma, Obsidian veya review isteğinde otomatik kullan; salt-okunur yönlendirme yapar ve kullanıcı yetkisini genişletmez.
---

# VixRex skill yönlendiricisi

Bu skill yalnız rota seçer; görevi uygulamaz.

Risk sınıfları, skill zincirleri, tekrar, oturum/PR ve test bütçesinin **tek sözleşme kaynağı** `docs/Ajan Calisma Akislari.md` dosyasıdır. Burada kopyalanmaz.

## Yönlendirme

1. Kullanıcının son isteğini ve açık yetki sınırını belirle.
2. `docs/Ajan Calisma Akislari.md` dosyasını baştan sona oku.
3. İsteği gerçek etkisine göre tablodaki risk veya özel rota ile eşleştir. Birden fazla sinyal varsa belgedeki önceliği uygula.
4. Aynı diff için tamamlanmış adımları belgedeki tekrar kuralına göre çıkar ve en küçük yeterli zinciri seç.
5. Seçilen her `.agents/skills/<ad>/SKILL.md` dosyasının varlığını doğrula. Eksik adımı uydurma; gerekirse `ask-matt` oku ve eksikliği raporla.
6. Rotayı bildir, sonra seçilen skill talimatlarını uygula:

```text
Risk: <rota belgesindeki sınıf veya salt-okunur>
Rota: vixrex-router → <skill> → <skill>
Gerekçe: <istekteki somut etki>
Yetki: <salt-okunur / kullanıcının açık değişiklik sınırı>
```

Ek skill gerekmiyorsa `Rota: vixrex-router` yaz.

## Sert güvenlik sınırı

- Bu skill dosya, issue, yorum veya handoff oluşturmaz/değiştirmez.
- Commit, push, PR, merge, deploy, migration veya canlı sistem işlemi başlatmaz.
- Bir alt skill'in tarifi kullanıcı yetkisinin yerine geçmez.
- Kullanıcı yalnız inceleme/teşhis istemişse rota salt-okunur kalır.
