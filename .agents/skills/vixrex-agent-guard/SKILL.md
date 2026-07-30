---
name: vixrex-agent-guard
description: Mandatory VixRex agent protocol. Enforces VIXREX_RULES.md vibe flow, hard gates, evidence levels, and protected-flow safety. Must be read before taking any actions.
---

# VixRex Ajan Muhafızı (vixrex-agent-guard)

Bu skill, `VIXREX_RULES.md` kurallarını uygular. Rules ile çelişirse **Rules üstündür**.

---

## Vibe protokol

1. **Söyle → yap.** Doğal dildeki uygulama isteği = o dilimin onayı. Mikro-onay isteme.
2. **Soru / fikir** ise kısa cevap veya seçenek sun; koda atlama.
3. **Tek dilim.** Bitince: hazır / hazır değil / test edilmedi / canlıda doğrulandı.
4. **Araştırma ≠ karar.** Öneri kilitsiz uygulanmaz.
5. **İlgisiz dosyaya dokunma.** Yan buluntu yalnız bildir.

## Sert kapılar

Kullanıcı aynı istekte açıkça demedikçe yapılmaz:

- commit
- push
- production deploy
- canlı DB / canlı migration
- production verisi silme
- ücret oluşturan işlem

Skill “commit et” dese bile kullanıcı “commit” demeden commit yok.

## Koruma

- Varsayım yok; kodu oku.
- Çalışan Kaydet / Yayınla / giriş / vitrin akışını kanıtsız bozma.
- Testi geçsin diye gevşetme veya silme.
- İstenmeyen özellik ekleme.

## İletişim

- Türkçe, kısa, sade.
- Durum cümlesi en fazla 20 kelime.
- Kanıt seviyesi abartılmaz (kodda var ≠ canlıda hazır).

## Kanıt seviyeleri

1. Kodda görüldü  
2. Statik kontrol geçti  
3. Otomatik test geçti  
4. Yerelde doğrulandı  
5. Canlıda doğrulandı  

---

Ayrıntı ve yüzey kapıları: kökteki `VIXREX_RULES.md`.
