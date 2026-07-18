-- ============================================================================
-- VixRex RLS & Security Tests (M1 v5)
-- supabase test db ile çalıştırılır.
-- 3 rol: anon, authenticated A, authenticated B.
-- Service-role yalnız setup/teardown ve katalog doğrulama bağlamında kullanılır.
-- ============================================================================

BEGIN;

-- ============================================================================
-- SETUP (service_role / postgres bağlamında)
-- ============================================================================

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000011', 'authenticated', 'authenticated', 'test-a@test.com', crypt('Test123!', gen_salt('bf')), now(), now(), now());
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000011', '{"sub": "00000000-0000-0000-0000-000000000011", "email": "test-a@test.com"}', 'email', '00000000-0000-0000-0000-000000000011', now(), now());

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000012', 'authenticated', 'authenticated', 'test-b@test.com', crypt('Test123!', gen_salt('bf')), now(), now(), now());
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000012', '{"sub": "00000000-0000-0000-0000-000000000012", "email": "test-b@test.com"}', 'email', '00000000-0000-0000-0000-000000000012', now(), now());

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000013', 'authenticated', 'authenticated', 'test-a-draft@test.com', crypt('Test123!', gen_salt('bf')), now(), now(), now());
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000013', '{"sub": "00000000-0000-0000-0000-000000000013", "email": "test-a-draft@test.com"}', 'email', '00000000-0000-0000-0000-000000000013', now(), now());

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000014', 'authenticated', 'authenticated', 'test-b@test.com2', crypt('Test123!', gen_salt('bf')), now(), now(), now());
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000014', '{"sub": "00000000-0000-0000-0000-000000000014", "email": "test-b@test.com2"}', 'email', '00000000-0000-0000-0000-000000000014', now(), now());

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000015', 'authenticated', 'authenticated', 'test-b-draft@test.com', crypt('Test123!', gen_salt('bf')), now(), now(), now());
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000015', '{"sub": "00000000-0000-0000-0000-000000000015", "email": "test-b-draft@test.com"}', 'email', '00000000-0000-0000-0000-000000000015', now(), now());

-- Legal documents (store'lardan önce; seed ile çakışırsa atla)
INSERT INTO public.legal_documents (document_type, version, title, subtitle, sections, is_active)
VALUES ('privacy', '1.0', 'Test Gizlilik', '', '[]'::jsonb, true)
ON CONFLICT (document_type, version) DO NOTHING;
INSERT INTO public.legal_documents (document_type, version, title, subtitle, sections, is_active)
VALUES ('terms', '1.0', 'Test Şartlar', '', '[]'::jsonb, true)
ON CONFLICT (document_type, version) DO NOTHING;
INSERT INTO public.legal_documents (document_type, version, title, subtitle, sections, is_active)
VALUES ('consent', '1.0', 'Test Rıza', '', '[]'::jsonb, true)
ON CONFLICT (document_type, version) DO NOTHING;

INSERT INTO public.stores (slug, name, is_published, user_id, edit_token,
  privacy_notice_acknowledged, privacy_notice_version, privacy_notice_hash,
  terms_accepted, terms_version, terms_hash,
  publication_consent_accepted, publication_consent_version, publication_consent_hash)
VALUES ('test-store-a', 'Store A', true, '00000000-0000-0000-0000-000000000011', 'test-edit-token-a-1234567890abcdef',
  true, '1.0', md5('privacy'||'|'||'1.0'||'|'||'Gizlilik Bildirimi'||'|'||''||'|'||'[]'),
  true, '1.0', md5('terms'||'|'||'1.0'||'|'||'Kullanım Şartları'||'|'||''||'|'||'[]'),
  true, '1.0', md5('consent'||'|'||'1.0'||'|'||'Açık Rıza Beyanı'||'|'||''||'|'||'[]'));
INSERT INTO public.stores (slug, name, is_published, user_id, edit_token)
VALUES ('test-store-a-draft', 'Store A Draft', false, '00000000-0000-0000-0000-000000000013', 'test-edit-token-a-draft-1234567890abcdef');
INSERT INTO public.stores (slug, name, is_published, user_id, edit_token,
  privacy_notice_acknowledged, privacy_notice_version, privacy_notice_hash,
  terms_accepted, terms_version, terms_hash,
  publication_consent_accepted, publication_consent_version, publication_consent_hash)
VALUES ('test-store-b', 'Store B', true, '00000000-0000-0000-0000-000000000014', 'test-edit-token-b-1234567890abcdef',
  true, '1.0', md5('privacy'||'|'||'1.0'||'|'||'Gizlilik Bildirimi'||'|'||''||'|'||'[]'),
  true, '1.0', md5('terms'||'|'||'1.0'||'|'||'Kullanım Şartları'||'|'||''||'|'||'[]'),
  true, '1.0', md5('consent'||'|'||'1.0'||'|'||'Açık Rıza Beyanı'||'|'||''||'|'||'[]'));
INSERT INTO public.stores (slug, name, is_published, user_id, edit_token)
VALUES ('test-store-b-draft', 'Store B Draft', false, '00000000-0000-0000-0000-000000000015', 'test-edit-token-b-draft-1234567890abcdef');

INSERT INTO public.booking_settings (store_slug, is_enabled, capacity)
VALUES ('test-store-a', true, 2);

INSERT INTO public.appointments (id, store_slug, customer_name, customer_phone, service_title, service_duration, appointment_time, status, token_hash, expires_at)
VALUES ('00000000-0000-0000-0000-000000000010', 'test-store-a', 'Müşteri X', '05550000000', 'Test Hizmet', 60, now() + interval '1 day', 'pending', encode(sha256('correct-token-1234567890abcdef'::bytea), 'hex'), now() + interval '2 hours');

-- ============================================================================
-- TESTS
-- ============================================================================

SELECT plan(19);

-- ── anon (Rol 1) ────────────────────────────────────────────────────────────

SET LOCAL role 'anon';
SET LOCAL request.jwt.claims = '{"sub": "00000000-0000-0000-0000-000000000000", "role": "anon", "aud": "authenticated"}';

-- 1: anon published store okuyabilmeli
SELECT is(
  (SELECT count(*)::int FROM public.stores WHERE is_published = true AND slug = 'test-store-a'),
  1,
  'anon published store okuyabilmeli'
);

-- 2: anon draft store okuyamamalı
SELECT is(
  (SELECT count(*)::int FROM public.stores WHERE slug = 'test-store-a-draft'),
  0,
  'anon draft store okuyamamalı'
);

-- 3: anon edit_token SELECT yetkisi yok (katalog kontrolü)
SELECT is(
  has_column_privilege('anon', 'public.stores', 'edit_token', 'SELECT'),
  false,
  'anon edit_token SELECT yetkisi yok'
);

-- 4: authenticated edit_token SELECT yetkisi yok (katalog kontrolü)
SELECT is(
  has_column_privilege('authenticated', 'public.stores', 'edit_token', 'SELECT'),
  false,
  'authenticated edit_token SELECT yetkisi yok'
);

-- ── authenticated A (Rol 2) ──────────────────────────────────────────────────

RESET role;
SET LOCAL role 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "00000000-0000-0000-0000-000000000001", "role": "authenticated", "aud": "authenticated"}';

-- 5: A, B'nin draft vitrini okuyamamalı
SELECT is(
  (SELECT count(*)::int FROM public.stores WHERE slug = 'test-store-b-draft'),
  0,
  'A, B draft okuyamamalı'
);

-- 6: A, B'nin vitrini üzerinde update yapamamalı
UPDATE public.stores SET name = 'UNCHANGED' WHERE slug = 'test-store-b';
RESET role;
SELECT is(
  (SELECT name FROM public.stores WHERE slug = 'test-store-b'),
  'Store B',
  'A, B update yapamamalı — isim değişmedi'
);

-- 7: A, B'nin vitrini üzerinde delete yapamamalı
SET LOCAL role 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "00000000-0000-0000-0000-000000000001", "role": "authenticated", "aud": "authenticated"}';
DELETE FROM public.stores WHERE slug = 'test-store-b';
RESET role;
SELECT is(
  (SELECT count(*)::int FROM public.stores WHERE slug = 'test-store-b'),
  1,
  'A, B delete yapamamalı — satır hâlâ mevcut'
);

-- ── authenticated B (Rol 3) ──────────────────────────────────────────────────

SET LOCAL role 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated", "aud": "authenticated"}';

-- 8: B, A'nın randevusunu değiştirememeli
UPDATE public.appointments SET status = 'confirmed' WHERE store_slug = 'test-store-a';
RESET role;
SELECT is(
  (SELECT status FROM public.appointments WHERE id = '00000000-0000-0000-0000-000000000010'),
  'pending',
  'B, A randevu değiştirememeli — status pending'
);

-- 9: B, A'nın booking ayarını değiştirememeli
SET LOCAL role 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated", "aud": "authenticated"}';
UPDATE public.booking_settings SET capacity = 99 WHERE store_slug = 'test-store-a';
RESET role;
SELECT is(
  (SELECT capacity FROM public.booking_settings WHERE store_slug = 'test-store-a'),
  2,
  'B, A booking change yapamamalı — kapasite 2'
);

-- 10: B, A'nın vitrini üzerinde update yapamamalı
SET LOCAL role 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated", "aud": "authenticated"}';
UPDATE public.stores SET name = 'HACKED' WHERE slug = 'test-store-a';
RESET role;
SELECT is(
  (SELECT name FROM public.stores WHERE slug = 'test-store-a'),
  'Store A',
  'B, A update yapamamalı — isim değişmedi'
);

-- 11: B, A'nın vitrini üzerinde delete yapamamalı
SET LOCAL role 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated", "aud": "authenticated"}';
DELETE FROM public.stores WHERE slug = 'test-store-a';
RESET role;
SELECT is(
  (SELECT count(*)::int FROM public.stores WHERE slug = 'test-store-a'),
  1,
  'B, A delete yapamamalı — satır hâlâ mevcut'
);

-- ── vitrin_views RLS ─────────────────────────────────────────────────────────

-- 12: vitrin_views RLS açık
SELECT is((SELECT rowsecurity FROM pg_tables WHERE schemaname='public' AND tablename='vitrin_views'), true, 'vitrin_views RLS açık');

-- 13: store_slug sütunu mevcut
SELECT has_column('public', 'vitrin_views', 'store_slug', 'store_slug sütunu mevcut');

-- 14: session_key sütunu mevcut
SELECT has_column('public', 'vitrin_views', 'session_key', 'session_key sütunu mevcut');

-- ── RLS açık tablolar ───────────────────────────────────────────────────────

-- 15: booking_settings RLS açık
SELECT is((SELECT rowsecurity FROM pg_tables WHERE schemaname='public' AND tablename='booking_settings'), true, 'booking_settings RLS açık');

-- 16: appointments RLS açık
SELECT is((SELECT rowsecurity FROM pg_tables WHERE schemaname='public' AND tablename='appointments'), true, 'appointments RLS açık');

-- ── slug unique ──────────────────────────────────────────────────────────────

-- 17: stores.slug benzersiz
SELECT col_is_unique('public', 'stores', 'slug', 'stores.slug benzersiz');

-- ── M3-engel: tokenlı misafir RPC ────────────────────────────────────────────

-- 18: get_appointment_by_token fonksiyonu mevcut (M3'te test edilecek)
SELECT has_function('public', 'get_appointment_by_token', ARRAY['text'], 'get_appointment_by_token RPC mevcut');

-- 19: cancel_appointment_by_token fonksiyonu mevcut (M3'te test edilecek)
SELECT has_function('public', 'cancel_appointment_by_token', ARRAY['text'], 'cancel_appointment_by_token RPC mevcut');

-- ============================================================================
-- CLEANUP (service_role / postgres bağlamında)
-- ============================================================================

RESET role;
DELETE FROM public.appointments WHERE store_slug LIKE 'test-store-%';
DELETE FROM public.booking_settings WHERE store_slug LIKE 'test-store-%';
DELETE FROM public.stores WHERE slug LIKE 'test-store-%';
DELETE FROM auth.identities WHERE user_id IN ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000012');
DELETE FROM auth.users WHERE id IN ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000012');

SELECT * FROM finish();

ROLLBACK;
