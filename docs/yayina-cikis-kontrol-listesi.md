# Yayına Çıkış Kontrol Listesi

> Canlı teste veya yayına geçmeden önce bu liste baştan sona uygulanır.
> Sıra değiştirilmez: **önce veritabanı, sonra ortam değişkenleri, en son kod.**
> Ters yapılırsa site kırılır — kod, olmayan bir tabloyu bekler.

Bu liste 2026-08-05'te yazıldı. Plan 13 adımın 10'unda; yayın için **henüz erken**.
Faz 11, 12 ve 13 bitmeden bu listeye başlanmaz.

---

## 1. Migration'lar — canlı Supabase'e uygulanacak

Hepsi yalnız **yerelde** uygulı. Canlıda hiçbiri yok. Sırayla uygulanır:

| Sıra | Dosya | Ne getiriyor |
|---|---|---|
| 1 | `20260804120000_fix_admins_rls_recursion.sql` | Admin panelinin `admins` tablosu izin düzeltmesi (özyinelemeli politika) |
| 2 | `20260804160000_20260804150000_add_store_working_drafts.sql` | `store_working_drafts` tablosu, `stores.version` kolonu |
| 3 | `20260804220000_add_owner_editable_section_labels.sql` | 12 yeni kolon: bölüm başlıkları ve `section_visibility` |
| 4 | `20260805000000_add_session_token_and_secure_draft_rpc.sql` | `session_token_hash`, güvenli oturum ve taslak okuma fonksiyonları |
| 5 | `20260805100000_add_working_draft_field_update.sql` | `update_working_draft_field` — alan güncelleme |

**Uygulamadan önce:**
- Canlı veritabanının yedeği alınır.
- Hiçbiri `DROP` içermiyor; hepsi `ADD COLUMN IF NOT EXISTS` ve `CREATE OR REPLACE`. Veri kaybı riski düşük, ama yedek yine de alınır.
- 3 numaralı migration 12 kolon ekliyor, hepsi NULL olabilir — mevcut vitrinler etkilenmez.

**Uygulandıktan sonra doğrulanır:**
```sql
select count(*) from information_schema.tables
  where table_name in ('owner_sessions','store_working_drafts');           -- 2 olmalı
select count(*) from information_schema.routines
  where routine_name in ('create_owner_session','consume_owner_session',
                         'get_working_draft_for_session',
                         'update_working_draft_field');                     -- 4 olmalı
select count(*) from information_schema.columns
  where table_name='stores' and column_name='section_visibility';           -- 1 olmalı
```

---

## 2. Ortam değişkenleri — Vercel'de tanımlanacak

**`vixrex-public` projesi:**

| Değişken | Neden gerekli | Yoksa ne olur |
|---|---|---|
| `OWNER_SESSION_SECRET` | Sahip oturum çerezini imzalar. En az 32 karakter, rastgele | Sahip oturumu hiç açılmaz |
| `SUPABASE_SERVICE_ROLE_KEY` | Görsel yükleme depoya yazarken kullanır | Görsel yükleme çalışmaz |
| `NEXT_PUBLIC_SUPABASE_URL` | mevcut | — |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | mevcut | — |

**Uyarı:** `SUPABASE_SERVICE_ROLE_KEY` bütün veritabanı korumalarını atlar. **Yalnız sunucu tarafında** kullanılır, `NEXT_PUBLIC_` önekiyle tanımlanmaz.

**`vixrex-app` (Flutter) projesi:** mevcut değişkenler yeterli. `INSTAGRAM_SYNC_ENABLED` hâlâ `false`; Meta onayı gelince açılır.

---

## 3. Test verisi temizliği

Sistemdeki **105 vitrinin tamamı geliştiricinin açtığı test hesabıdır.** Gerçek kullanıcı yoktur.

Yayına çıkmadan önce karar verilecek:

- Test vitrinleri silinecek mi, gizlenecek mi?
- **Seed edilmiş demo vitrinlerde uydurma değerlendirme puanı var** (`rating_score` 4.9, `review_count` 128 gibi). Var olmayan işletmeye ait uydurma puan göstermek tüketiciye yönelik yanıltıcı ticari uygulama sayılır. En azından "Örnek Vitrin" rozeti konur ve puan alanları boşaltılır.
- Yerelde test için yayınlanan `demo-teknofix` yalnız yerel; canlıyı etkilemez.

---

## 4. Kod — en son

Beş migration uygulandıktan **ve** ortam değişkenleri tanımlandıktan sonra PR #40 `main`'e birleştirilir.

**`main`'e merge etmek yayınlamaktır** — Vercel `main`'i izliyor.

---

## 5. Yayın sonrası doğrulama

Deploy'un "başarılı" görünmesi sitenin çalıştığı anlamına gelmez. Şunlar **gözle** doğrulanır:

- [ ] Müşteri bir vitrini açabiliyor (`/v/:slug`)
- [ ] Müşteri görünümünde `data-vixrex-editable` **hiç yok** (sahip aracı sızmıyor)
- [ ] Flutter panelinden "Önizle" sahip modunu açıyor
- [ ] Sahip panelinde bir alan düzenlenip kaydediliyor
- [ ] Kaydedilen değişiklik **müşteri görünümünde görünmüyor** (yayınlanana kadar)
- [ ] Görsel yükleme çalışıyor
- [ ] **İki Vercel projesi ayrı ayrı** kontrol edilir; birinin başarılı olması diğeri hakkında bilgi vermez

---

## 6. Geri dönüş

- Kod: `git revert` ile geri alınır, Vercel yeniden yayınlar.
- **Migration geri alınamaz kabul edilir.** Eklenen kolonlar NULL olabilir olduğu için kodu geri almak yeterlidir; tabloları düşürmek gerekmez.
- Sorun sahip modundaysa, müşteri rotasına dokunmadan sahip modu kapatılabilir (oturum çerezi doğrulanmazsa fail-closed devreye girer ve müşteri görünümü gösterilir).
