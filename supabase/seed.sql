-- ============================================================================
-- VixRex Local Seed (M1)
-- Yalnız sahte test verisi. Gerçek e-posta, telefon, token veya UUID içermez.
-- ============================================================================

-- ============================================================================
-- 1. SAHTE AUTH KULLANICILARI (deterministic UUID)
-- ============================================================================
-- Supabase local'de auth.users tablosuna service_role context'inde INSERT yapılabilir.

-- Kullanıcı A: sahte-aylin@test.com (butik sahibi)
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  confirmed_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '00000000-0000-0000-0000-000000000001',
  'authenticated',
  'authenticated',
  'sahte-aylin@test.com',
  crypt('SahteTest123!', gen_salt('bf')),
  now(),
  now(),
  now(),
  '',
  '',
  '',
  '',
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"full_name": "Aylin Test"}',
  false,
  now()
);

INSERT INTO auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  '{"sub": "00000000-0000-0000-0000-000000000001", "email": "sahte-aylin@test.com"}',
  'email',
  now(),
  now(),
  now()
);

-- Kullanıcı B: sahte-mehmet@test.com (fırın sahibi)
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  confirmed_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '00000000-0000-0000-0000-000000000002',
  'authenticated',
  'authenticated',
  'sahte-mehmet@test.com',
  crypt('SahteTest123!', gen_salt('bf')),
  now(),
  now(),
  now(),
  '',
  '',
  '',
  '',
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"full_name": "Mehmet Test"}',
  false,
  now()
);

INSERT INTO auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000002',
  '{"sub": "00000000-0000-0000-0000-000000000002", "email": "sahte-mehmet@test.com"}',
  'email',
  now(),
  now(),
  now()
);

-- ============================================================================
-- 2. SAHTE MAĞAZA A SAHİBİ (butik) — user_id bağlı
-- ============================================================================
INSERT INTO public.stores (
  slug,
  name,
  business_type,
  description,
  corporate_bio,
  whatsapp,
  instagram,
  website,
  address,
  theme,
  status,
  is_published,
  is_store,
  kategori,
  shelf_image_url,
  logo_url,
  gallery_items,
  products,
  offerings,
  marketplace_links,
  working_hours,
  province_name,
  district_name,
  user_id,
  edit_token
) VALUES (
  'sahte-butik-aylin',
  'Aylin Butik',
  'Kadın giyim / butik',
  'Şık ve günlük kadın giyim ürünlerini keşfedin.',
  'Aylin Butik, günlük kombinler ve özel tasarım parçalar sunan yerel bir butiktir.',
  '05551112233',
  '@aylinbutik',
  '',
  'Atatürk Cad. No:10, Merkez, İstanbul',
  'Premium',
  'Açık',
  true,
  true,
  'Giyim & Butik',
  'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?auto=format&fit=crop&w=1400&q=80',
  '',
  '[
    {"id": "g1", "imageUrl": "https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?auto=format&fit=crop&w=1200&q=80", "title": "Mağaza içi"},
    {"id": "g2", "imageUrl": "https://images.unsplash.com/photo-1558171813-4c088753af8f?auto=format&fit=crop&w=1200&q=80", "title": "Yeni sezon"}
  ]'::jsonb,
  '[
    {"id": "p1", "name": "Keten Elbise", "price": "450 TL", "category": "Elbise", "description": "Yaz için hafif keten elbise", "isVisible": true},
    {"id": "p2", "name": "Günlük Tişört", "price": "180 TL", "category": "Tişört", "description": "Pamuklu günlük tişört", "isVisible": true}
  ]'::jsonb,
  '[
    {"id": "o1", "title": "Yeni Sezon Elbiseler", "description": "Şık ve rahat günlük elbise alternatifleri", "price": "400-800 TL"}
  ]'::jsonb,
  '[{"id": "1", "platform": "Instagram", "url": "instagram.com/aylinbutik"}]'::jsonb,
  'Pazartesi-Cuma 09:00-19:00, Cumartesi 10:00-17:00',
  'İstanbul',
  'Merkez',
  '00000000-0000-0000-0000-000000000001',
  'sahte-edit-token-aylin-1234567890abcdef'
);

-- ============================================================================
-- 3. SAHTE MAĞAZA B SAHİBİ (gıda/fırın) — user_id bağlı
-- ============================================================================
INSERT INTO public.stores (
  slug,
  name,
  business_type,
  description,
  corporate_bio,
  whatsapp,
  instagram,
  website,
  address,
  theme,
  status,
  is_published,
  is_store,
  kategori,
  shelf_image_url,
  logo_url,
  gallery_items,
  products,
  offerings,
  marketplace_links,
  working_hours,
  province_name,
  district_name,
  user_id,
  edit_token
) VALUES (
  'sahte-firin-mehmet',
  'Mehmet Fırın',
  'Fırın / Unlu mamul',
  'Taze ekmek ve unlu mamuller her gün fırından.',
  'Mehmet Fırın, geleneksel taş fırında üretilen ekmek ve unlu mamulleriyle hizmet verir.',
  '05552223344',
  '@mehmetfirin',
  '',
  'İstiklal Cad. No:25, Merkez, İzmir',
  'Premium',
  'Açık',
  true,
  true,
  'Fırın & Unlu Mamul',
  'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1400&q=80',
  '',
  '[
    {"id": "g1", "imageUrl": "https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80", "title": "Fırın içi"},
    {"id": "g2", "imageUrl": "https://images.unsplash.com/photo-1549931319-a545753467c8?auto=format&fit=crop&w=1200&q=80", "title": "Taze ekmek"}
  ]'::jsonb,
  '[
    {"id": "p1", "name": "Taş Fırın Ekmeği", "price": "25 TL", "category": "Ekmek", "description": "Günlük taze ekşi mayalı ekmek", "isVisible": true},
    {"id": "p2", "name": "Poğaça", "price": "15 TL", "category": "Unlu mamul", "description": "Peynirli ve zeytinli poğaça", "isVisible": true}
  ]'::jsonb,
  '[
    {"id": "o1", "title": "Günlük Taze Ekmek", "description": "Sabah 06:00\'dan itibaren taze", "price": "25 TL"}
  ]'::jsonb,
  '[{"id": "1", "platform": "Instagram", "url": "instagram.com/mehmetfirin"}]'::jsonb,
  'Her gün 06:00-20:00',
  'İzmir',
  'Merkez',
  '00000000-0000-0000-0000-000000000002',
  'sahte-edit-token-mehmet-1234567890abcdef'
);

-- ============================================================================
-- 4. YAYINLANMAMIŞ MAĞAZA (misafir) — user_id yok
-- ============================================================================
INSERT INTO public.stores (
  slug,
  name,
  business_type,
  description,
  whatsapp,
  address,
  theme,
  status,
  is_published,
  is_store,
  kategori,
  edit_token
) VALUES (
  'sahte-misafir-taslak',
  'Taslak Mağaza',
  'Butik',
  'Bu mağaza henüz yayınlanmadı.',
  '05550000000',
  'Test Adresi, Test İlçe',
  'Premium',
  'Taslak',
  false,
  false,
  'Giyim & Butik',
  'sahte-edit-token-misafir-1234567890abcdef'
);

-- ============================================================================
-- 5. KATEGORİ ŞABLON GÖRSELLERİ (varsa category_image_templates tablosu)
-- ============================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'category_image_templates') THEN
    INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order)
    VALUES
      ('butik', 'Butik', 'cover', 'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?auto=format&fit=crop&w=1400&q=80', 'Butik kapağı', 1),
      ('butik', 'Butik', 'gallery', 'https://images.unsplash.com/photo-1558171813-4c088753af8f?auto=format&fit=crop&w=1200&q=80', 'Butik galerisi', 1)
    ON CONFLICT DO NOTHING;
  END IF;
END $$;
