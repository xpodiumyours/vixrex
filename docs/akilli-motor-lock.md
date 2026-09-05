# Vixrex Akıllı Motor — ANA PLAN 🔒

> **Ana hedef kilitli:** AI/LLM API olmadan; Vixrex'in 46 vitrin alanını güvenli, deterministik, kalıcı, geri alınabilir ve esnaf için anlaşılır biçimde yöneten; ileride Blog ve Dijital Çarşı domain'lerini aynı çekirdeğe güvenli biçimde takabilecek üretim seviyesi Vixrex Akıllı Motoru.

Durumlar: ✅ tamamlandı · 🔄 çalışılıyor · ⬜ bekliyor · 🔒 kilitli

Alt dallar araştırma/uygulama sırasında bölünebilir veya birleştirilebilir. **Ana hedef, güvenlik kuralları, kapsam sınırı ve katman sırası değişmez.**

---

## KATMAN 0 — Mevcut durum denetimi ✅

- ✅ 46 alan ve tek field-schema zinciri doğrulandı.
- ✅ Flutter + Next NLU incelendi.
- ✅ Supabase conversation / pending / working draft / RPC sınırları incelendi.
- ✅ Flutter ↔ Next state/persistence farkları çıkarıldı.
- ✅ Idempotency, concurrency, audit, undo ve parity açıkları çıkarıldı.
- ✅ Sahiplik Asistan UX + onboarding kapsam içine alındı.

**Sonuç:** 46-alan çekirdeği değerli; eksik olan ortak güvenli motor kontratıydı.

---

## KATMAN 1 — Global araştırma ✅

- ✅ AI'sız deterministic command-engine yaklaşımı doğrulandı.
- ✅ State machine / pure decision / executor ayrımı doğrulandı.
- ✅ Token/phrase matcher yaklaşımı doğrulandı.
- ✅ JSON Schema 2020-12 referans alındı.
- ✅ PostgreSQL concurrency/idempotency prensipleri incelendi.
- ✅ OWASP API güvenlik sınırları incelendi.
- ✅ W3C/WAI status/error/undo UX prensipleri incelendi.
- ✅ Supabase 2026 güvenlik/değişiklikleri kontrol edildi.

Yeni framework ekleme kararı alınmadı; mevcut Dart + TypeScript + Supabase stack korunuyor.

---

## KATMAN 2 — VIXREX FIT ✅

### 2A — 46 alan motoru
- ✅ 46 alan tek field-schema kaynağı.
- ✅ Niyet sözlüğü kanonik shared kaynak olarak belirlendi.
- ✅ Matcher kusuru (`tel` → `otel`) doğrulandı ve çözümü LOCK edildi.
- ✅ Validator parity açıkları çıkarıldı.
- ✅ Özel akış alanları sınıflandırıldı.
- ✅ 46/46 davranış matrisi oluşturuldu.

### 2B — Tek karar sözleşmesi
- ✅ Decision ≠ persistence sınırı LOCK edildi.
- ✅ `validated_action` typed contract LOCK edildi.
- ✅ Action lifecycle LOCK edildi.
- ✅ Flutter'ın karar içinde save yapması ve Next'in erken `Kaydettim` demesi BUILD açığı olarak kesinleştirildi.

### 2C — Domain Router
- ✅ Router kontratı LOCK edildi.
- ✅ İlk aktif domain yalnız `storefront`.
- 🔒 Blog interpreter.
- 🔒 Dijital Çarşı interpreter.

---

## KATMAN 2.5 — ESNAF UX FIT ✅

### Sahiplik Asistan UX
- ✅ Balon/sheet motor UX kapsamına alındı.
- ✅ Gönder → küçül → gerçek loading → vitrin görünür davranışı LOCK edildi.
- ✅ Success / failed / queued / partial / undo state'leri LOCK edildi.
- ✅ “Anlaşıldı” ile “kaydedildi” ayrıldı.
- ✅ Erişilebilir status davranışı LOCK edildi.

### Onboarding / Asistan tanıma
- ✅ Mevcut onboarding state-machine korunacak.
- ✅ Kısa/dürüst yetenek tanıtımı LOCK edildi.
- ✅ Onboarding local setup draft ile owner-edit canonical draft sınırı netleştirildi.
- ✅ 46 alan listesi veya teknik jargon esnafa yüklenmeyecek.

---

## KATMAN 3 — SECURITY / STATE / DATA ✅ MİMARİ LOCK

> Buradaki ✅, **tasarım/güvenlik kararının tamamlandığı** anlamına gelir. Mevcut production kodun hepsinin uygulanmış olduğu anlamına gelmez; uygulama KATMAN 5'tedir.

### 3A — Authorization
- ✅ Web HttpOnly owner-session korunacak.
- ✅ Flutter auth yolu yalnız permanent/non-anonymous owner için.
- ✅ Client store/slug/column iddiası authorization sayılmayacak.
- ✅ Protected/legal bypass yasak.

### 3B — Pending state
- ✅ Supabase `assistant_conversations.pending_slot` canonical.
- ✅ local storage yalnız cache.
- ✅ pending envelope + server validation LOCK.

### 3C — Draft truth
- ✅ Owner-edit canonical hakikat `store_working_drafts`.
- ✅ Flutter ↔ Next owner-edit parity hedefi LOCK.
- ✅ Onboarding pre-publish local draft bilinçli ayrı lifecycle.

### 3D — Idempotency / concurrency
- ✅ `actionId` / `commandId` sözleşmesi.
- ✅ `expectedDraftVersion` sözleşmesi.
- ✅ stale-write conflict davranışı.
- ✅ DB-level receipt uniqueness.

### 3E — Audit / Undo
- ✅ Mevcut `audit_logs` kullanılacak.
- ✅ old/new/action/version receipt.
- ✅ Assistant Undo = action öncesi taslak değeri.
- ✅ `UNDO_CONFLICT` daha yeni değişikliği korur.

### 3F — Kill-switch
- ✅ Mevcut `feature_flags/get_feature_flags()` kullanılacak.
- ✅ fail-closed.
- ✅ client + server kontrolü.
- ✅ manuel owner edit kill-switch'ten etkilenmez.

---

# KATMAN 4 — FINAL ARCHITECTURE LOCK ✅

Tüm alt LOCK belgeleri karşılaştırıldı ve final mimari tek belgede birleştirildi:

- ✅ Matcher
- ✅ Validator / özel akış
- ✅ Pending state
- ✅ Typed action
- ✅ Action lifecycle
- ✅ Executor sınırı
- ✅ Authorization
- ✅ Owner-edit draft hakikati
- ✅ Idempotency + concurrency
- ✅ Audit + safe Undo
- ✅ Çoklu action kısmi başarı
- ✅ Flutter/Next parity modeli
- ✅ Sahiplik UX lifecycle
- ✅ Onboarding davranışı
- ✅ Domain Router
- ✅ Runtime kill-switch
- ✅ 46/46 test sözleşmesi
- ✅ CI / PR / preview gate

**Final belge:** `docs/akilli-motor-architecture-lock.md`

### LOCK kararı

**✅ ARCHITECTURE LOCK TAMAMLANDI.**

Bu, motorun uygulanmış olduğu anlamına gelmez. Artık BUILD sırasında mimari yeniden tasarlanmayacak.

---

# KATMAN 5 — CORE BUILD 🔄

## 5.0 — Baseline / parity üretim hattı ✅

- ✅ `shared/vixrex_niyet_sozlugu.json` → Dart generator.
- ✅ Generator 46 anahtar + etiket/tip/kolon/bölüm eşitliğini kanonik alan şemasına karşı doğruluyor.
- ✅ CI intent-dictionary drift kontrolü.
- ✅ Tek shared motor parity fixture iskeleti.
- ✅ Runtime motor davranışı değiştirilmedi.
- ✅ Draft PR #417 `schema-drift` job'ında generator + drift kontrolü gerçek CI'da geçti.

## 5.1 — Fail-closed kill-switch 🔄

- ⬜ `vixrex_smart_engine_enabled`.
- ⬜ `vixrex_smart_engine_storefront_enabled`.
- ⬜ Flutter + Next client guard.
- ⬜ Authoritative server guard.
- ⬜ OFF → manual owner edit devam.

## 5.2 — Matcher + Validator parity ⬜

- ⬜ substring matcher kaldırılacak.
- ⬜ token/phrase matcher.
- ⬜ controlled Turkish suffix.
- ⬜ fuzzy yalnız clarification.
- ⬜ semantic validator parity.
- ⬜ special-flow classification.

## 5.3 — Pure Decision + Typed Action ⬜

- ⬜ Flutter NLU içinden mutation/save side-effect çıkarılacak.
- ⬜ Next NLU içinden erken success metni çıkarılacak.
- ⬜ ortak canonical decision/action sonucu.

## 5.4 — Canonical Pending State ⬜

- ⬜ Flutter Supabase pending adapter.
- ⬜ local cache fallback.
- ⬜ pending envelope server validation.
- ⬜ cross-client test.

## 5.5 — Authoritative Assistant Mutation ⬜

- ⬜ expected version.
- ⬜ action/command id.
- ⬜ web owner-session.
- ⬜ permanent Flutter auth ownership.
- ⬜ shared server semantic validation.
- ⬜ idempotency receipt + audit.

## 5.6 — Safe Undo + Multi-action ⬜

- ⬜ action-level Undo.
- ⬜ partial success.
- ⬜ conflict stop.

## 5.7 — Next Owner UX lifecycle ⬜

- ⬜ existing sheet/collapse → real executing state.
- ⬜ success/error/partial/undo.
- ⬜ accessible status.

## 5.8 — Flutter owner-edit adapter/lifecycle ⬜

- ⬜ canonical working draft.
- ⬜ same action/result contract.
- ⬜ queued_offline ayrı state.

## 5.9 — Special-flow security parity ⬜

- ⬜ image security parity.
- ⬜ il/ilçe/GPS.
- ⬜ çalışma saatleri.
- ⬜ toggle/url edge cases.

## 5.10 — Core Build doğrulaması ⬜

- ⬜ ilgili unit/integration testler.
- ⬜ PR CI.
- ⬜ preview.
- ⬜ motor kaynaklı yeni regresyon = 0.

---

# KATMAN 6 — 46/46 FIELD VERIFY 🔒

Her alan:

```text
schema
→ intent
→ extraction
→ validation
→ special-flow
→ typed action
→ authorization
→ persistence
→ idempotency
→ Flutter/Next parity
→ UX result
→ undo (uygunsa)
```

zincirinin tamamını geçmeden ✅ alamaz.

---

# KATMAN 7 — ESNAF VERIFY 🔒

- kısa/günlük Türkçe,
- yazım hatası,
- eksik/geçersiz bilgi,
- iki alan,
- yanlış tekrar gönderim,
- mobil,
- reload,
- cihaz/yüzey değişimi,
- hata/undo,
- teknik terimsiz kullanım.

---

# KATMAN 8 — AKILLI MOTOR LOCK 🔒

Aşağıdakiler tamamlanmadan açılmaz:

- ⬜ 46/46.
- ⬜ canonical pending.
- ⬜ canonical owner draft.
- ⬜ Flutter/Next parity.
- ⬜ idempotency/concurrency.
- ⬜ audit/Undo.
- ⬜ runtime kill-switch.
- ⬜ sahiplik UX.
- ⬜ onboarding doğrulaması.
- ⬜ esnaf senaryoları.
- ⬜ gerekli CI tamamen yeşil.
- ⬜ public/storefront regresyonu yok.

Sonuç yalnız:

**✅ AKILLI MOTOR LOCK AÇILDI**

veya

**❌ LOCK KAPALI**

olabilir.

---

# KATMAN 9 — BLOG / DİJİTAL ÇARŞI UNLOCK 🔒

Akıllı Motor LOCK açılmadan Blog/Dijital Çarşı assistant domain BUILD'i yok.

---

## Değiştirilemez güvenlik kuralları

1. Belirsiz mesaj veri değiştirmez.
2. Motor anlamadığı şey için başarı söylemez.
3. `validated` = `kaydedildi` değildir.
4. Success yalnız authoritative persistence sonrası.
5. Protected/legal alan bypass edilmez.
6. Aynı logical action ikinci mutation üretmez.
7. Stale state sessiz overwrite edilmez.
8. Flutter permanent-user auth yolu anonymous kullanıcıya açılmaz.
9. Client column/store iddiası yetki değildir.
10. Local cache canonical truth değildir.
11. Görsel alanlarda düz URL ana esnaf UX'i değildir.
12. `vitrinFieldSchema` zinciri korunur.
13. Yeni paralel persistence/validation sistemi kurulmaz.
14. Main'e doğrudan geliştirme commit'i yok.
15. Blog/Dijital Çarşı kapsamına taşma yok.

---

## Şu anki gerçek durum

**KATMAN 0 ✅**  
**KATMAN 1 ✅**  
**KATMAN 2 ✅ Vixrex-FIT/LOCK**  
**KATMAN 2.5 ✅ UX-FIT/LOCK**  
**KATMAN 3 ✅ Security/State Architecture LOCK**  
**KATMAN 4 ✅ FINAL ARCHITECTURE LOCK**  
**KATMAN 5.0 ✅ BASELINE/PARITY PIPELINE**  
**KATMAN 5.1 🔄 KILL-SWITCH**  
**KATMAN 5.2–5.10 ⬜ BUILD DEVAMI**  
**KATMAN 6 🔒 46/46 VERIFY**  
**KATMAN 7 🔒 ESNAF VERIFY**  
**KATMAN 8 🔒 AKILLI MOTOR LOCK**  
**KATMAN 9 🔒 BLOG / DİJİTAL ÇARŞI**
