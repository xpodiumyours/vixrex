# Katman 2.5 — Katman 3 Öncesi Profesyonel Sertleştirme

Durum: **TAMAMLANDI**

Katman 3 kapısı açıldı; sıradaki adım yalnız **RESEARCH** olabilir.

## 1. Migration geçmişi eşitliği

Amaç: Repo migration dosya adları ile canlı Supabase migration history sürümlerini birebir hizalamak.

Tamamlanan hizalama:
- `20260904140908_owner_catalog_session_read.sql`
- `20260904182313_add_vixrex_blog_articles.sql`
- `20260904195755_add_vixrex_blog_library_metadata.sql`
- `20260904205134_optimize_vixrex_blog_rls.sql`
- `20260904205201_review_vixrex_blog_drafts.sql`

Son branch kodu üzerinde yerel Supabase migration zinciri sıfırdan kuruldu ve GRANT güvenlik bekçisi geçti.

Durum: **TAMAMLANDI.**

## 2. Blog RLS performans sertleştirmesi

`vixrex_blog_articles` ve `vixrex_blog_article_relations` admin policy'lerindeki `auth.uid()` kontrolleri yetki davranışı değiştirilmeden `(select auth.uid())` biçimine alındı ve canlı Supabase'e uygulandı.

Canlı Performance Advisor tekrar kontrolünde bu iki blog tablosu için `auth_rls_initplan` uyarısı kalmadı.

Not: Advisor'da Vixrex blogu dışındaki eski tablolar için ayrı performans uyarıları ve blog SELECT tarafında çoklu permissive policy uyarısı bulunabiliyor. Bunlar bu sertleştirme maddesinin kapsamı değildir ve yetki genişletmesi yapılmadı.

Durum: **TAMAMLANDI.**

## 3. Gerçek allow/deny + admin API davranış testleri

Geçici GitHub Actions doğrulamasında gerçek yerel Supabase + production Next.js birlikte çalıştırıldı.

Doğrulama turunda:
- migration zinciri sıfırdan geçti
- GRANT bekçisi geçti
- production build geçti
- Next.js production server açıldı
- gerçek RLS + admin API davranış testi geçti
- cleanup geçti

Bu test kaynak metni aramakla sınırlı değildir; çalışan DB/API davranışını kontrol eder.

Durum: **TAMAMLANDI.**

## 4. Auth security durumunu doğru raporlama

CI `auth-config-check` işi secret'lar yoksa canlı Auth güvenliğini kanıtlamaz. Bu nedenle CI sonucu ile canlı Supabase Security Advisor sonucu ayrı tutuluyor.

Canlı Advisor'ın güncel sonucu:
- `Leaked Password Protection`: **kapalı**

Bu durum blog Katman 2.5 tarafından oluşturulmadı ve blog RLS doğrulamasının geçtiği anlamıyla karıştırılmıyor.

Durum: **TAMAMLANDI.**

## 5. Taslak blog içerik doğruluğu ve provenance

İki mevcut merkezi taslak güncel birincil Google kaynaklarıyla yeniden gözden geçirildi.

Düzeltilen başlıca sorunlar:
- Google doğrulamasının zorunlu tek posta kartı yöntemi olduğu izlenimi kaldırıldı.
- sabit indeksleme/sıralama süresi vaatleri kaldırıldı.
- görünürlük/sıralama garantisi verilmedi.
- `source_urls` gerçek birincil kaynaklarla dolduruldu.

Canlı DB son kontrolü:
- `isletmemi-googleda-nasil-gosteririm`: `draft`, 3 kaynak URL
- `kuafor-icin-internet-sitesi`: `draft`, 2 kaynak URL
- hiçbir yazı bu işlemle yayınlanmadı

Durum: **TAMAMLANDI.**

## Final doğrulama

Son geçici doğrulama turu başarıyla tamamlandı. Kanıt alındıktan sonra geçici Katman 2.5 workflow dosyası branch'ten kaldırıldı.

## Çıkış kararı

Beş madde de teknik kanıtla tamamlandı. **Katman 3 blokesi kaldırıldı.**

Sıradaki plan adımı:
**Katman 3 — Vitrine Yazı Çekme / Taslak Enjeksiyonu: RESEARCH**

Katman 3 BUILD, `RESEARCH → UX-FIT → SECURITY/RISK → LOOK → LOCK` tamamlanmadan başlamaz.
