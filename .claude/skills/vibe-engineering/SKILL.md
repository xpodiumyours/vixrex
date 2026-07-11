---
description: VixRex vibe engineering. Her session başında yükle. Hata kalıpları, token, DoD yaptırımı.
argument-hint: session start
---

# Vibe Engineering

> Vibe coding hatalarını kes; bitmiş özellik üret. DoD fail = task fail (CLAUDE.md).

---

## 1. Hata Kalıpları

| Kalıp | Belirti | Önlem |
|---|---|---|
| **Context Collapse** | Önceki karara aykırı kod | Session başında CLAUDE.md |
| **Scope Drift** | Her prompt'ta yeni özellik | Tek feature; gerisini plana yaz |
| **Hallucinated API** | Var olmayan API | Dokümantasyon / pub.dev |
| **Over-engineering** | Basit soruna karmaşık çözüm | En basit yaklaşım |
| **Forgotten Edge Cases** | Empty/error unutulur | loading + empty + error |
| **Context Rot** | Uzun session yavaşlar | ~80K'da yeni session |
| **Empty Shell** | Boş callback | DoD fail = task fail |
| **Dead Code (bu task)** | Bu task'ta yazıldı, parent'a bağlanmadı | Aynı task'ta **bağla** |
| **Plan kabuğu** | Eski mega-plan peşinde koşma | `KURTARMA_OPERASYONU.md` — çekirdek önce |
| **Checkbox Lie** | Plan `[x]` erken | Yalnızca **Complete** DoD sonrası `[x]` |
| **Fake Complete** | SSS→KVKK, Docs→anasayfa, "yakında" SnackBar | Wire ≠ Complete; içerik yoksa `[ ]` + not |

**İçerik kuralı:** Menü/özellik adı ne vaat ediyorsa o ürün içeriği konur (SSS=soru-cevap, Docs=kılavuz). Yanlış hedefe yönlendirmek Complete değildir.

**Kabuk kuralı:** Kullanılmayan widget = bağla veya dokunma. Kurtarmada çekirdek akış (Vitrinim/yayın/Keşfet) öncelikli; checkbox avı yok.

---

## 2. Token

- Max 5 dosya oku; bind için screen+widget istisna (**max 6**)
- Önce `grep`, sonra `offset/limit` ile oku
- Batch parallel oku; production-checklist'i session'a alma

---

## 3. Güvenlik (özet)

- Service role client-side yasak · RLS bozma · her endpoint auth
- API key hardcoded yasak · env kullan · HTTPS

Detay → `/production-checklist` (yalnızca release).

---

## 4. Kod Kalitesi

- `Result<T>` · Controller → Service → Repository · screen'den direkt Supabase yok
- Dosya ≤200 satır · fonksiyon ≤50 · boş `catch` yasak · Türkçe hata mesajı

---

## 5. UI

- Her ekran: loading (Skeleton) + empty + error (+ retry)
- Touch target ≥44px · Semantics · reduced motion

---

## 6. Prompt (tek şablon)

```
VixRex [özellik]. Complete DoD zorunlu (etiket=içerik).
Önce grep; bağla + ürün içeriği yerleştir.
YAPMA: plan kabuğunu yeniden yazma, boş callback, yanlış sayfa yaması, plan erken [x].
Wire-only ise checkbox [ ] bırak. Kabuk varsa düzenle + Complete bağla.
```

---

*CLAUDE.md Integration DoD bağlayıcıdır. Fast-path'te ağır gate yok.*
