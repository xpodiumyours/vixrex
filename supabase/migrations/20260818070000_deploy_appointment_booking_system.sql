-- Randevu/rezervasyon sisteminin TAMAMINI aktif migration zincirine
-- kurar (2026-08-18, Casper onayıyla — "evet kur gerçekten çalışır hale
-- gelsin").
--
-- NEDEN VAR
-- V-08 (attack-vectors.md) araştırılırken bulundu: hem Flutter hem web
-- istemcisi randevu rezervasyonu/erteleme/takip için UI ve RPC çağrıları
-- İÇERİYOR (BookingWizardClient.tsx, BookingTrackerClient.tsx,
-- appointment_tracker_screen.dart, booking_service.dart) ama gerçek
-- production veritabanına salt-okunur bağlanıp doğrulandığında
-- (`supabase db dump --linked`, 2026-08-18) şu RPC'lerin HİÇBİRİ orada
-- yoktu: get_public_booking_slots, create_appointment_request,
-- get_appointment_by_token, cancel_appointment_by_token,
-- request_appointment_reschedule, respond_to_appointment,
-- mask_appointment_name. `booking_blocks` ve `appointment_reschedule_
-- requests` tabloları da yoktu. Yani randevu özelliği müşteri tarafında
-- görünüyor ama arka planda TAMAMEN ÇALIŞMIYORDU — bir "randevu al"
-- denemesi RPC bulunamadı hatasıyla başarısız olurdu.
--
-- Bonus: delete_user_account() zaten booking_blocks ve appointment_
-- reschedule_requests'ten DELETE yapmaya ÇALIŞIYORDU (temel şema
-- migration'ında var) — bu tablolar yoksa mağazası olan bir kullanıcının
-- hesap silme isteği de hata verirdi. Bu migration onu da düzeltir.
--
-- KAYNAK
-- migrations_arsiv/20260622000001_add_booking_system.sql (orijinal) +
-- migrations_arsiv/20260710000002_fix_appointment_rls_and_pii.sql
-- (auth.uid() sarmalama, politika sertleştirme) + migrations_arsiv/
-- 20260717000009_p1_security_hardening.sql (anon SELECT revoke) —
-- production'da ZATEN UYGULANMIŞ olan appointments politika/grant
-- sertleştirmeleri (doğrulandı, aşağıdaki DROP/CREATE'ler o yüzden
-- production'da no-op, yerel/taze ortamlarda gerekli) + V-08 kapasite
-- yeniden kontrol düzeltmesi (respond_to_appointment'ın onay dalı,
-- attack-vectors.md).
--
-- appointments tablosunda DEĞİŞEN TEK ŞEY: iki YENİ sütun (token_hash,
-- expires_at, mevcut satırlar için geriye dönük dolduruluyor) ve status
-- kısıtının GENİŞLETİLMESİ (eski değerler de kabul edilmeye devam eder).
-- Var olan hiçbir satır/sütun silinmez veya daraltılmaz.

-- ── 1) appointments: eksik sütunlar + genişletilmiş status sözlüğü ─────
ALTER TABLE "public"."appointments" ADD COLUMN IF NOT EXISTS "token_hash" text;
ALTER TABLE "public"."appointments" ADD COLUMN IF NOT EXISTS "expires_at" timestamptz;

UPDATE "public"."appointments"
SET "token_hash" = encode(sha256("token"::bytea), 'hex')
WHERE "token_hash" IS NULL;

UPDATE "public"."appointments"
SET "expires_at" = CASE
  WHEN "status" = 'confirmed' THEN '9999-12-31 23:59:59+00'::timestamptz
  ELSE "created_at" + interval '2 hours'
END
WHERE "expires_at" IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'appointments_token_hash_key'
  ) THEN
    ALTER TABLE "public"."appointments" ADD CONSTRAINT "appointments_token_hash_key" UNIQUE ("token_hash");
  END IF;
END $$;

ALTER TABLE "public"."appointments" DROP CONSTRAINT IF EXISTS "appointments_status_check";
ALTER TABLE "public"."appointments" ADD CONSTRAINT "appointments_status_check" CHECK (
  "status" = ANY (ARRAY[
    'pending'::text, 'confirmed'::text, 'cancelled'::text, 'completed'::text,
    'rejected'::text, 'cancelled_by_customer'::text, 'cancelled_by_store'::text, 'expired'::text
  ])
);

CREATE INDEX IF NOT EXISTS "idx_appointments_token_hash" ON "public"."appointments" USING "btree" ("token_hash");

-- ── 2) eksik tablolar ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "public"."booking_blocks" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "store_slug" text NOT NULL REFERENCES "public"."stores"("slug") ON DELETE CASCADE,
  "block_date" date NOT NULL,
  "start_time" time without time zone,
  "end_time" time without time zone,
  "reason" text,
  "created_at" timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS "idx_booking_blocks_store_date" ON "public"."booking_blocks" USING "btree" ("store_slug", "block_date");

CREATE TABLE IF NOT EXISTS "public"."appointment_reschedule_requests" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "appointment_id" uuid NOT NULL REFERENCES "public"."appointments"("id") ON DELETE CASCADE,
  "requested_time" timestamptz NOT NULL,
  "status" text DEFAULT 'pending' CONSTRAINT "check_reschedule_status" CHECK (status IN ('pending', 'approved', 'rejected')),
  "created_at" timestamptz DEFAULT now()
);

ALTER TABLE "public"."booking_blocks" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."appointment_reschedule_requests" ENABLE ROW LEVEL SECURITY;

-- ── 3) politikalar (production'da appointments/booking_settings için
--       zaten uygulanmış sertleştirilmiş desenle aynı) ─────────────────
DROP POLICY IF EXISTS "Allow owners select appointments" ON "public"."appointments";
DROP POLICY IF EXISTS "Allow owners update appointments" ON "public"."appointments";
DROP POLICY IF EXISTS "Owners can view their store appointments" ON "public"."appointments";
CREATE POLICY "Owners can view their store appointments" ON "public"."appointments" FOR SELECT TO authenticated USING (
  (SELECT auth.uid()) IS NOT NULL
  AND EXISTS (SELECT 1 FROM "public"."stores" s WHERE s.slug = appointments.store_slug AND s.user_id = (SELECT auth.uid()))
);
DROP POLICY IF EXISTS "Owners can update their store appointments" ON "public"."appointments";
CREATE POLICY "Owners can update their store appointments" ON "public"."appointments" FOR UPDATE TO authenticated USING (
  (SELECT auth.uid()) IS NOT NULL
  AND EXISTS (SELECT 1 FROM "public"."stores" s WHERE s.slug = appointments.store_slug AND s.user_id = (SELECT auth.uid()))
) WITH CHECK (
  (SELECT auth.uid()) IS NOT NULL
  AND EXISTS (SELECT 1 FROM "public"."stores" s WHERE s.slug = appointments.store_slug AND s.user_id = (SELECT auth.uid()))
);
REVOKE SELECT ON TABLE "public"."appointments" FROM anon;

DROP POLICY IF EXISTS "Allow public read booking blocks" ON "public"."booking_blocks";
CREATE POLICY "Allow public read booking blocks" ON "public"."booking_blocks" FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "Allow owners to manage booking blocks" ON "public"."booking_blocks";
DROP POLICY IF EXISTS "Owners can manage booking blocks" ON "public"."booking_blocks";
CREATE POLICY "Owners can manage booking blocks" ON "public"."booking_blocks" FOR ALL TO authenticated USING (
  EXISTS (SELECT 1 FROM "public"."stores" s WHERE s.slug = booking_blocks.store_slug AND s.user_id = (SELECT auth.uid()))
);

DROP POLICY IF EXISTS "Allow owners select reschedule requests" ON "public"."appointment_reschedule_requests";
DROP POLICY IF EXISTS "Owners can view reschedule requests" ON "public"."appointment_reschedule_requests";
CREATE POLICY "Owners can view reschedule requests" ON "public"."appointment_reschedule_requests" FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM "public"."appointments" a JOIN "public"."stores" s ON s.slug = a.store_slug WHERE a.id = appointment_reschedule_requests.appointment_id AND s.user_id = (SELECT auth.uid()))
);
DROP POLICY IF EXISTS "Allow owners update reschedule requests" ON "public"."appointment_reschedule_requests";
DROP POLICY IF EXISTS "Owners can update reschedule requests" ON "public"."appointment_reschedule_requests";
CREATE POLICY "Owners can update reschedule requests" ON "public"."appointment_reschedule_requests" FOR UPDATE TO authenticated USING (
  EXISTS (SELECT 1 FROM "public"."appointments" a JOIN "public"."stores" s ON s.slug = a.store_slug WHERE a.id = appointment_reschedule_requests.appointment_id AND s.user_id = (SELECT auth.uid()))
);

-- ── 4) yardımcı fonksiyon ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.mask_appointment_name(p_name text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_parts text[];
  v_result text[] := '{}';
  v_part text;
BEGIN
  v_parts := regexp_split_to_array(trim(p_name), '\s+');
  FOREACH v_part IN ARRAY v_parts LOOP
    IF length(v_part) > 0 THEN
      v_result := array_append(v_result, left(v_part, 1) || '***');
    END IF;
  END LOOP;
  RETURN array_to_string(v_result, ' ');
END;
$$;

-- ── 5) müsait saatleri hesapla ──────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_public_booking_slots(p_store_slug text, p_date date)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_settings public.booking_settings%rowtype;
  v_dow text;
  v_hours jsonb;
  v_start_str text;
  v_end_str text;
  v_lunch_start_str text;
  v_lunch_end_str text;
  v_lunch_active boolean;
  v_slot timestamptz;
  v_end_limit timestamptz;
  v_capacity int;
  v_slot_time_str text;
  v_lunch_start time;
  v_lunch_end time;
  v_slot_time time;
  v_blocked boolean;
  v_active_appts_count int;
  v_appt record;
  v_confirmed_names text[];
  v_has_pending boolean;
  v_slots_result jsonb := '[]'::jsonb;
  v_slot_obj jsonb;
BEGIN
  SELECT * INTO v_settings FROM public.booking_settings WHERE store_slug = p_store_slug;
  IF NOT FOUND OR NOT v_settings.is_enabled THEN
    RETURN '[]'::jsonb;
  END IF;

  v_capacity := v_settings.capacity;
  v_dow := extract(isodow FROM p_date)::text;
  v_hours := v_settings.working_hours->v_dow;

  IF v_hours IS NULL OR NOT (v_hours->>'active')::boolean THEN
    RETURN '[]'::jsonb;
  END IF;

  v_start_str := v_hours->>'start';
  v_end_str := v_hours->>'end';

  v_lunch_active := (v_settings.lunch_break->>'active')::boolean;
  IF v_lunch_active THEN
    v_lunch_start := (v_settings.lunch_break->>'start')::time;
    v_lunch_end := (v_settings.lunch_break->>'end')::time;
  END IF;

  v_slot := (p_date::text || ' ' || v_start_str)::timestamp with time zone;
  v_end_limit := (p_date::text || ' ' || v_end_str)::timestamp with time zone;

  WHILE v_slot < v_end_limit LOOP
    v_slot_time := v_slot::time;
    v_slot_time_str := to_char(v_slot_time, 'HH24:MI');

    IF v_lunch_active AND v_slot_time >= v_lunch_start AND v_slot_time < v_lunch_end THEN
      v_blocked := true;
    ELSE
      SELECT EXISTS (
        SELECT 1 FROM public.booking_blocks
        WHERE store_slug = p_store_slug
          AND block_date = p_date
          AND (
            (start_time IS NULL AND end_time IS NULL) OR
            (v_slot_time >= start_time AND v_slot_time < end_time)
          )
      ) INTO v_blocked;
    END IF;

    IF NOT v_blocked THEN
      v_active_appts_count := 0;
      v_confirmed_names := '{}'::text[];
      v_has_pending := false;

      FOR v_appt IN (
        SELECT customer_name, status, service_duration, appointment_time
        FROM public.appointments
        WHERE store_slug = p_store_slug
          AND status IN ('pending', 'confirmed')
          AND (status = 'confirmed' OR expires_at > now())
          AND appointment_time <= v_slot
          AND v_slot < appointment_time + (service_duration || ' minutes')::interval
      ) LOOP
        v_active_appts_count := v_active_appts_count + 1;
        IF v_appt.status = 'confirmed' THEN
          v_confirmed_names := array_append(v_confirmed_names, public.mask_appointment_name(v_appt.customer_name));
        ELSE
          v_has_pending := true;
        END IF;
      END LOOP;

      v_slot_obj := jsonb_build_object(
        'time', v_slot_time_str,
        'capacity_total', v_capacity,
        'capacity_used', v_active_appts_count,
        'slots_left', greatest(0, v_capacity - v_active_appts_count),
        'confirmed_names', to_jsonb(v_confirmed_names),
        'has_pending', v_has_pending
      );

      v_slots_result := v_slots_result || jsonb_build_array(v_slot_obj);
    END IF;

    v_slot := v_slot + interval '15 minutes';
  END LOOP;

  RETURN v_slots_result;
END;
$$;

-- ── 6) randevu talebi oluştur ────────────────────────────────────────
-- search_path'e 'extensions' eklendi (orijinal arşiv dosyasında yoktu):
-- gen_random_bytes pgcrypto'dan geliyor ve bu kurulumda extensions
-- şemasında duruyor — yalnız pg_catalog,public ile bulunamıyordu (yerelde
-- test edilirken görüldü).
CREATE OR REPLACE FUNCTION public.create_appointment_request(
  p_store_slug text,
  p_customer_name text,
  p_customer_phone text,
  p_customer_notes text,
  p_service_title text,
  p_service_price text,
  p_service_duration int,
  p_appointment_time timestamptz
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
AS $$
DECLARE
  v_settings public.booking_settings%rowtype;
  v_lock_ok boolean;
  v_daily_count int;
  v_plaintext_token text;
  v_token_hash text;
  v_appt_id uuid;
  v_appt_end timestamptz;
  v_slot timestamptz;
  v_active_appts_count int;
  v_dow text;
  v_hours jsonb;
  v_start_time time;
  v_end_time time;
  v_lunch_active boolean;
  v_lunch_start time;
  v_lunch_end time;
  v_slot_time time;
  v_blocked boolean;
BEGIN
  SELECT count(*) INTO v_daily_count
  FROM public.appointments
  WHERE customer_phone = p_customer_phone
    AND created_at > now() - interval '24 hours';

  IF v_daily_count >= 5 THEN
    RAISE EXCEPTION 'DAILY_LIMIT_EXCEEDED';
  END IF;

  SELECT pg_try_advisory_xact_lock(hashtext(p_store_slug)) INTO v_lock_ok;
  IF NOT v_lock_ok THEN
    RAISE EXCEPTION 'STORE_BUSY_TRY_AGAIN';
  END IF;

  SELECT * INTO v_settings FROM public.booking_settings WHERE store_slug = p_store_slug;
  IF NOT FOUND OR NOT v_settings.is_enabled THEN
    RAISE EXCEPTION 'BOOKING_DISABLED';
  END IF;

  v_dow := extract(isodow FROM p_appointment_time)::text;
  v_hours := v_settings.working_hours->v_dow;
  IF v_hours IS NULL OR NOT (v_hours->>'active')::boolean THEN
    RAISE EXCEPTION 'STORE_CLOSED_ON_THIS_DAY';
  END IF;

  v_start_time := (v_hours->>'start')::time;
  v_end_time := (v_hours->>'end')::time;
  v_slot_time := p_appointment_time::time;

  IF v_slot_time < v_start_time OR v_slot_time >= v_end_time THEN
    RAISE EXCEPTION 'OUTSIDE_WORKING_HOURS';
  END IF;

  v_lunch_active := (v_settings.lunch_break->>'active')::boolean;
  IF v_lunch_active THEN
    v_lunch_start := (v_settings.lunch_break->>'start')::time;
    v_lunch_end := (v_settings.lunch_break->>'end')::time;
    IF v_slot_time >= v_lunch_start AND v_slot_time < v_lunch_end THEN
      RAISE EXCEPTION 'LUNCH_BREAK_BLOCK';
    END IF;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.booking_blocks
    WHERE store_slug = p_store_slug
      AND block_date = p_appointment_time::date
      AND (
        (start_time IS NULL AND end_time IS NULL) OR
        (v_slot_time >= start_time AND v_slot_time < end_time)
      )
  ) INTO v_blocked;
  IF v_blocked THEN
    RAISE EXCEPTION 'DATE_TIME_BLOCKED';
  END IF;

  v_appt_end := p_appointment_time + (p_service_duration || ' minutes')::interval;
  v_slot := p_appointment_time;

  WHILE v_slot < v_appt_end LOOP
    SELECT count(*) INTO v_active_appts_count
    FROM public.appointments
    WHERE store_slug = p_store_slug
      AND status IN ('pending', 'confirmed')
      AND (status = 'confirmed' OR expires_at > now())
      AND appointment_time <= v_slot
      AND v_slot < appointment_time + (service_duration || ' minutes')::interval;

    IF v_active_appts_count >= v_settings.capacity THEN
      RAISE EXCEPTION 'CAPACITY_FULL';
    END IF;

    v_slot := v_slot + interval '15 minutes';
  END LOOP;

  v_plaintext_token := encode(gen_random_bytes(16), 'hex');
  v_token_hash := encode(sha256(v_plaintext_token::bytea), 'hex');
  v_appt_id := gen_random_uuid();

  INSERT INTO public.appointments (
    id, store_slug, customer_name, customer_phone, customer_notes,
    service_title, service_price, service_duration, appointment_time,
    status, token, token_hash, expires_at
  ) VALUES (
    v_appt_id, p_store_slug, trim(p_customer_name), trim(p_customer_phone), trim(p_customer_notes),
    trim(p_service_title), trim(p_service_price), p_service_duration, p_appointment_time,
    'pending', v_plaintext_token, v_token_hash, now() + interval '2 hours'
  );

  RETURN jsonb_build_object('appointment_id', v_appt_id, 'token', v_plaintext_token);
END;
$$;

-- ── 7) token ile randevu detayı oku ─────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_appointment_by_token(p_token text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_token_hash text;
  v_appt record;
  v_reschedule record;
  v_store_name text;
BEGIN
  v_token_hash := encode(sha256(p_token::bytea), 'hex');

  SELECT a.*, s.name AS store_name
  INTO v_appt
  FROM public.appointments a
  JOIN public.stores s ON s.slug = a.store_slug
  WHERE a.token_hash = v_token_hash;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_reschedule
  FROM public.appointment_reschedule_requests
  WHERE appointment_id = v_appt.id AND status = 'pending'
  ORDER BY created_at DESC
  LIMIT 1;

  RETURN jsonb_build_object(
    'id', v_appt.id,
    'store_slug', v_appt.store_slug,
    'store_name', v_appt.store_name,
    'customer_name', v_appt.customer_name,
    'customer_phone', v_appt.customer_phone,
    'customer_notes', v_appt.customer_notes,
    'service_title', v_appt.service_title,
    'service_price', v_appt.service_price,
    'service_duration', v_appt.service_duration,
    'appointment_time', v_appt.appointment_time,
    'status', v_appt.status,
    'created_at', v_appt.created_at,
    'expires_at', v_appt.expires_at,
    'reschedule_request', CASE
      WHEN v_reschedule.id IS NOT NULL THEN jsonb_build_object(
        'id', v_reschedule.id,
        'requested_time', v_reschedule.requested_time,
        'status', v_reschedule.status
      )
      ELSE NULL
    END
  );
END;
$$;

-- ── 8) müşteri kendi randevusunu iptal eder ─────────────────────────
CREATE OR REPLACE FUNCTION public.cancel_appointment_by_token(p_token text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_token_hash text;
BEGIN
  v_token_hash := encode(sha256(p_token::bytea), 'hex');

  UPDATE public.appointments
  SET status = 'cancelled_by_customer'
  WHERE token_hash = v_token_hash
    AND status IN ('pending', 'confirmed');

  RETURN FOUND;
END;
$$;

-- ── 9) müşteri erteleme talep eder ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.request_appointment_reschedule(p_token text, p_new_time timestamptz)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_token_hash text;
  v_appt public.appointments%rowtype;
  v_settings public.booking_settings%rowtype;
  v_appt_end timestamptz;
  v_slot timestamptz;
  v_active_appts_count int;
  v_lock_ok boolean;
BEGIN
  v_token_hash := encode(sha256(p_token::bytea), 'hex');

  SELECT * INTO v_appt FROM public.appointments WHERE token_hash = v_token_hash;
  IF NOT FOUND OR v_appt.status NOT IN ('pending', 'confirmed') THEN
    RAISE EXCEPTION 'APPOINTMENT_NOT_ACTIVE';
  END IF;

  SELECT pg_try_advisory_xact_lock(hashtext(v_appt.store_slug)) INTO v_lock_ok;
  IF NOT v_lock_ok THEN
    RAISE EXCEPTION 'STORE_BUSY_TRY_AGAIN';
  END IF;

  SELECT * INTO v_settings FROM public.booking_settings WHERE store_slug = v_appt.store_slug;
  IF NOT FOUND OR NOT v_settings.is_enabled THEN
    RAISE EXCEPTION 'BOOKING_DISABLED';
  END IF;

  v_appt_end := p_new_time + (v_appt.service_duration || ' minutes')::interval;
  v_slot := p_new_time;

  WHILE v_slot < v_appt_end LOOP
    SELECT count(*) INTO v_active_appts_count
    FROM public.appointments
    WHERE store_slug = v_appt.store_slug
      AND id <> v_appt.id
      AND status IN ('pending', 'confirmed')
      AND (status = 'confirmed' OR expires_at > now())
      AND appointment_time <= v_slot
      AND v_slot < appointment_time + (service_duration || ' minutes')::interval;

    IF v_active_appts_count >= v_settings.capacity THEN
      RAISE EXCEPTION 'CAPACITY_FULL';
    END IF;

    v_slot := v_slot + interval '15 minutes';
  END LOOP;

  UPDATE public.appointment_reschedule_requests
  SET status = 'rejected'
  WHERE appointment_id = v_appt.id AND status = 'pending';

  INSERT INTO public.appointment_reschedule_requests (
    appointment_id, requested_time, status
  ) VALUES (
    v_appt.id, p_new_time, 'pending'
  );

  RETURN true;
END;
$$;

-- ── 10) sahip randevuya yanıt verir (V-08 kapasite FİX'i dahil) ────
CREATE OR REPLACE FUNCTION public.respond_to_appointment(
  p_appointment_id uuid,
  p_action text,
  p_reschedule_action text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_appt public.appointments%rowtype;
  v_resched public.appointment_reschedule_requests%rowtype;
  v_is_owner boolean;
  v_settings public.booking_settings%rowtype;
  v_appt_end timestamptz;
  v_slot timestamptz;
  v_active_appts_count int;
  v_lock_ok boolean;
BEGIN
  SELECT * INTO v_appt FROM public.appointments WHERE id = p_appointment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'APPOINTMENT_NOT_FOUND';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.stores
    WHERE slug = v_appt.store_slug AND user_id = auth.uid()
  ) INTO v_is_owner;

  IF NOT v_is_owner THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;

  IF p_action IS NOT NULL THEN
    IF p_action = 'confirm' THEN
      UPDATE public.appointments
      SET status = 'confirmed', expires_at = '9999-12-31 23:59:59+00'::timestamptz
      WHERE id = p_appointment_id;
    ELSIF p_action = 'reject' THEN
      UPDATE public.appointments SET status = 'rejected' WHERE id = p_appointment_id;
    ELSE
      RAISE EXCEPTION 'INVALID_ACTION';
    END IF;
    RETURN true;
  END IF;

  IF p_reschedule_action IS NOT NULL THEN
    SELECT * INTO v_resched
    FROM public.appointment_reschedule_requests
    WHERE appointment_id = p_appointment_id AND status = 'pending'
    ORDER BY created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'NO_PENDING_RESCHEDULE';
    END IF;

    IF p_reschedule_action = 'approve' THEN
      -- V-08 FİX (attack-vectors.md, 2026-08-18): orijinal tasarımda onay
      -- dalı kapasiteyi yeniden kontrol etmiyordu — talep anından onay
      -- anına kadar aynı slot başka bir randevuyla dolmuş olabilirdi
      -- (çift rezervasyon). request_appointment_reschedule ile AYNI
      -- kilit + kapasite döngüsü eklendi.
      SELECT pg_try_advisory_xact_lock(hashtext(v_appt.store_slug)) INTO v_lock_ok;
      IF NOT v_lock_ok THEN
        RAISE EXCEPTION 'STORE_BUSY_TRY_AGAIN';
      END IF;

      SELECT * INTO v_settings FROM public.booking_settings WHERE store_slug = v_appt.store_slug;
      IF NOT FOUND OR NOT v_settings.is_enabled THEN
        RAISE EXCEPTION 'BOOKING_DISABLED';
      END IF;

      v_appt_end := v_resched.requested_time + (v_appt.service_duration || ' minutes')::interval;
      v_slot := v_resched.requested_time;

      WHILE v_slot < v_appt_end LOOP
        SELECT count(*) INTO v_active_appts_count
        FROM public.appointments
        WHERE store_slug = v_appt.store_slug
          AND id <> v_appt.id
          AND status IN ('pending', 'confirmed')
          AND (status = 'confirmed' OR expires_at > now())
          AND appointment_time <= v_slot
          AND v_slot < appointment_time + (service_duration || ' minutes')::interval;

        IF v_active_appts_count >= v_settings.capacity THEN
          RAISE EXCEPTION 'CAPACITY_FULL';
        END IF;

        v_slot := v_slot + interval '15 minutes';
      END LOOP;

      UPDATE public.appointment_reschedule_requests SET status = 'approved' WHERE id = v_resched.id;

      UPDATE public.appointments
      SET appointment_time = v_resched.requested_time,
          status = 'confirmed',
          expires_at = '9999-12-31 23:59:59+00'::timestamptz
      WHERE id = p_appointment_id;

    ELSIF p_reschedule_action = 'reject' THEN
      UPDATE public.appointment_reschedule_requests SET status = 'rejected' WHERE id = v_resched.id;
    ELSE
      RAISE EXCEPTION 'INVALID_ACTION';
    END IF;
    RETURN true;
  END IF;

  RETURN false;
END;
$$;

-- ── 11) yetkiler ─────────────────────────────────────────────────────
REVOKE EXECUTE ON FUNCTION public.get_public_booking_slots(text, date) FROM public;
GRANT EXECUTE ON FUNCTION public.get_public_booking_slots(text, date) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.create_appointment_request(text, text, text, text, text, text, int, timestamptz) FROM public;
GRANT EXECUTE ON FUNCTION public.create_appointment_request(text, text, text, text, text, text, int, timestamptz) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.get_appointment_by_token(text) FROM public;
GRANT EXECUTE ON FUNCTION public.get_appointment_by_token(text) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.cancel_appointment_by_token(text) FROM public;
GRANT EXECUTE ON FUNCTION public.cancel_appointment_by_token(text) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.request_appointment_reschedule(text, timestamptz) FROM public;
GRANT EXECUTE ON FUNCTION public.request_appointment_reschedule(text, timestamptz) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.respond_to_appointment(uuid, text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.respond_to_appointment(uuid, text, text) TO authenticated;
