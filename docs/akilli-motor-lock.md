# Vixrex Akıllı Motor — Araştırma ve LOCK Planı

> Ana hedef kilitli: AI API olmadan; Vixrex'in 46 vitrin alanını güvenli, deterministik, kalıcı ve geri alınabilir biçimde yöneten; ileride Blog ve Dijital Çarşı domain'lerini aynı asistana takabilecek üretim seviyesi çekirdek.

Durumlar: ✅ tamamlandı · 🔄 çalışılıyor · ⬜ bekliyor · 🔒 kilitli

## KATMAN 0 — Mevcut durum denetimi ✅

- ✅ 46 alanın tek şema üretim hattı doğrulandı.
- ✅ Next.js ve Flutter NLU boruları incelendi.
- ✅ Supabase conversation / pending / working draft / RPC sınırları incelendi.
- ✅ Flutter ↔ Next state ve persistence farkları tespit edildi.
- ✅ Idempotency, concurrency, audit ve parity açıkları tespit edildi.
- ✅ Sahiplik Asistan UX ve onboarding yüzeyleri kapsam içine alındı.
- ✅ Sonuç: mevcut 46 alan motoru değerli; ancak ortak domain/task/state/action çekirdeği Katman 4 için henüz yeterli değil.

## KATMAN 1 — Global araştırma 🔄

### 1A — AI'sız modern motor mimarisi ✅

Araştırma sonucu kullanılacak prensipler:

1. **State machine / statechart**: durumlar ve geçişler açık, test edilebilir ve deterministik olacak.
2. **Rule/token/phrase matching**: sınırlı 46 alan terminolojisi için model eğitimi yerine token/phrase tabanlı kurallar kullanılabilir.
3. **Schema-driven contract**: alan/action/state verisi tipli ve şema ile doğrulanabilir olacak.
4. **Decision ≠ effect**: motor karar üretir; gerçek veri değişikliğini executor yapar.
5. **Persistent state**: pending/task state cihaz belleğine bağlı kalmaz.
6. **Idempotent mutation**: aynı istemin tekrar gönderilmesi ikinci etki üretmez.
7. **Optimistic concurrency / row locking**: iki istemci sessizce birbirinin verisini ezemez.
8. **Audit + undo**: her mutation izlenebilir ve uygun işlemler geri alınabilir.

Referanslar:
- XState v5 / Stately state machine ve actor docs
- JSON Schema 2020-12
- spaCy rule-based token/phrase matching yaklaşımı (mimari referans; Vixrex'e Python/spaCy bağımlılığı ekleme kararı değildir)
- PostgreSQL 17 concurrency/row locking
- OWASP API Security Top 10 2023
- Unicode UAX #15 normalization

### 1B — Güncel teknoloji uygunluğu ✅

- ✅ JSON Schema'nın güncel sürümü 2020-12.
- ✅ XState dokümantasyonunun kararlı önerilen hattı v5; alpha agent katmanı referans alınmayacak.
- ✅ PostgreSQL 17 row-level locking ve transaction mekanizmaları Vixrex'in mevcut DB'siyle uyumlu.
- ✅ Supabase 2026 Data API değişiklikleri incelendi; yeni tablolar/fonksiyonlar için explicit grant + RLS yaklaşımı korunacak.
- ✅ Unicode normalization/case handling yalnız matching katmanında kullanılacak; kullanıcıya gösterilen metin bozulmayacak.

### 1C — Deterministik NLU araştırması 🔄

- ✅ Sonlu terminoloji için rule-based phrase/token matching uygun.
- ✅ Exact phrase + token-pattern yaklaşımı substring eşleşmeden daha güvenli.
- ⬜ Vixrex için kesin matcher skor/öncelik kuralları LOCK edilmedi.
- ⬜ Yazım hatası toleransı için deterministic fuzzy sınırı LOCK edilmedi.

## KATMAN 2 — Vixrex FIT 🔄

### 2A — 46 alan motoru 🔄

- ✅ `VIXREX_NIYET_SOZLUGU.length === 46` test ile korunuyor.
- ✅ Her alanın anahtar / eş anlam / örnek ifade / beklenen veri tipi kontratı var.
- ✅ Normalize, resolver, extractor, validator ayrımları var.
- ✅ Çok alanlı cümle için mevcut sınırlandırma düzeltmeleri var.
- ❌ Resolver şu an normalize edilmiş `includes()` ile eşleşiyor; kelime/token sınırı yok.
- ❌ Kısa eş anlamlar yanlış pozitif üretebilir. Örnek: telefon alanındaki `tel`, `otel` kelimesinin içinde de eşleşebilir.
- ⬜ 46/46 için yanlış pozitif / yanlış negatif / özel akış matrisi tamamlanmadı.

### 2B — Tek karar sözleşmesi 🔄

- ✅ Next.js NLU karar sonucu döndürüp yazmayı ayrı API hattında yapabiliyor.
- ❌ Flutter NLU aynı katmanda executor çağırıp `saveLocally()` yapıyor.
- ⬜ Flutter ve Next aynı typed action kontratına geçirilmedi.

### 2C — Domain Router 🔒

Hedef:

```text
Vixrex Asistan
  ├─ storefront (ilk aktif domain)
  ├─ blog 🔒
  ├─ digital_carsi 🔒
  └─ gelecek domain'ler 🔒
```

- ❌ Mevcut üst seviye domain router yok.
- 🔒 Blog/Dijital Çarşı BUILD açılmaz.

## KATMAN 2.5 — Esnaf UX FIT 🔄

### 2.5A — Sahiplik Asistan UX 🔄

Kapsam içinde:
- balon/sheet açılma-kapanma
- mesaj gönderimi
- loading / işlem sürüyor durumu
- vitrin görünürlüğü
- başarı / hata / netleştirme
- çoklu alan sonucu
- undo / geri al
- erişilebilir status mesajları

Doğrulama kuralı: motor teknik olarak başarılı olsa bile kullanıcı ne olduğunu anlayamıyorsa madde tamamlanmış sayılmaz.

### 2.5B — Asistan tanıma / onboarding 🔄

Mevcut Flutter onboarding zaten ayrı bir adım makinesi (`welcome → ... → done`) içeriyor; bu yüzey motor projesinin parçasıdır.

LOCK öncesi tanımlanacak:
- Asistan ne yapar?
- Hangi tür komutlar verilebilir?
- Neyi otomatik yapmaz?
- Ne zaman netleştirme ister?
- Değişikliğin gerçekleştiğini esnaf nasıl görür?
- Geri alma nasıl sunulur?

## KATMAN 3 — Security / State / Data 🔄

### 3A — Yetkilendirme ✅ temel / 🔄 motor seviyesi

Canlı Supabase doğrulaması:
- ✅ `assistant_conversations`, `assistant_messages`, `owner_flow_states`, `store_working_drafts`, `audit_logs`: RLS açık.
- ✅ Kritik assistant RPC'lerinde `PUBLIC EXECUTE` kapalı.
- ✅ Asistan conversation/pending RPC'leri authenticated kullanıcıya sınırlı.
- ✅ Owner draft RPC'leri mevcut owner-session doğrulama sınırını koruyor.

LOCK gereği:
- ⬜ Yeni action/state yüzeyi explicit grants + least privilege ile tasarlanacak.
- ⬜ Client'tan gelen alan/domain bilgisi tek başına yetki kabul edilmeyecek.

### 3B — Kalıcı state 🔄

- ✅ Supabase `assistant_conversations.pending_slot` mevcut.
- ✅ Next.js pending'i Supabase RPC ile kullanıyor.
- ❌ Flutter `VixrexConversationMemory` hâlâ SharedPreferences kullanıyor.
- ⬜ Supabase kanonik, local storage yalnız cache olacak.

### 3C — Idempotency 🔄

- ✅ Assistant messages'ta client message id altyapısı mevcut.
- ❌ Race-safe/atomic idempotent sonuç garantisi kanıtlanmadı.
- ❌ Field mutation için action idempotency kontratı yok.
- ⬜ Her mutation benzersiz action/idempotency kimliği taşıyacak.

### 3D — Concurrency 🔄

- ✅ `owner_flow_states` version kontrolü kullanıyor.
- ✅ restore RPC satır kilidi kullanıyor.
- ❌ normal field update için expected-version/idempotency kontratı yok.
- ⬜ Sessiz lost-update yasak.

### 3E — Audit / Undo 🔄

- ✅ `audit_logs` altyapısı mevcut.
- ✅ Next tarafında field restore mekanizması mevcut.
- ❌ Assistant mutation zinciri audit_logs'a otomatik bağlı değil.
- ⬜ action → old/new → actor → source → rollback ilişkisi kurulacak.

### 3F — Runtime kill switch 🔄

- ❌ Flutter motoru compile-time sabit ile açık; operasyonel runtime kill-switch değil.
- ⬜ Motor uzaktan/güvenli şekilde devre dışı bırakılabilir olacak.

## KATMAN 4 — ARCHITECTURE LOCK 🔒

Aşağıdakiler kesinleşmeden BUILD açılmaz:

- ⬜ Domain Router
- ⬜ Matcher/intent scoring kuralları
- ⬜ Slot/state sözleşmesi
- ⬜ Typed action sözleşmesi
- ⬜ Executor sınırı
- ⬜ Supabase state modeli
- ⬜ Idempotency + concurrency modeli
- ⬜ Audit + undo modeli
- ⬜ Flutter/Next parity modeli
- ⬜ Sahiplik UX state'leri
- ⬜ Onboarding davranışları
- ⬜ 46/46 test matrisi
- ⬜ CI gate

## BUILD ve sonrası 🔒

- KATMAN 5 — CORE BUILD 🔒
- KATMAN 6 — 46/46 FIELD VERIFY 🔒
- KATMAN 7 — ESNAF VERIFY 🔒
- KATMAN 8 — AKILLI MOTOR LOCK 🔒
- KATMAN 9 — BLOG / DİJİTAL ÇARŞI UNLOCK 🔒

## Değiştirilemez güvenlik kuralları

1. Belirsiz mesaj veri değiştirmez.
2. Motorun anlamadığı şey için başarı mesajı üretmesi yasaktır.
3. Protected/legal alanlar genel motor tarafından bypass edilmez.
4. Aynı action'ın tekrar gönderimi ikinci mutation üretmez.
5. Flutter ve Next aynı girdide aynı intent/value/action sonucunu vermeden parity tamamlanmış sayılmaz.
6. Kullanıcıya loading/success/error/undo durumu açık gösterilir.
7. Mevcut `vitrinFieldSchema` tek kaynak zinciri korunur.
8. Main'e merge yalnız LOCK sonrası, ilgili testler ve CI yeşilken yapılır.

## Şu anki durum

- KATMAN 0 ✅
- KATMAN 1A ✅
- KATMAN 1B ✅
- KATMAN 1C 🔄
- KATMAN 2 🔄
- KATMAN 2.5 🔄
- KATMAN 3 🔄
- KATMAN 4 🔒
- BUILD 🔒
