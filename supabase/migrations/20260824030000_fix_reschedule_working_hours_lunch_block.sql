-- ============================================================================
-- V-19 Fix: Reschedule missing working hours/lunch/block checks
-- ============================================================================
-- SORUN: request_appointment_reschedule fonksiyonu sadece kapasite kontrolü
-- yapıyor (V-08 fix). Çalışma saatleri, öğle arası ve bloke edilmiş
-- zaman dilimleri KONTROL EDİLMİYOR. Bu, müşterinin randevuyu
-- çalışma saati dışına, öğle arasına veya bloke edilmiş bir slota
-- erteleyebilmesi demektir.
--
-- ÇÖZÜM: get_available_slots ve create_appointment ile AYNI mantığı
-- request_appointment_reschedule'a ekle.
--
-- Yapı:
--   booking_settings.working_hours: jsonb { "1": {"active": true, "start": "09:00", "end": "18:00"}, ... }
--   booking_settings.lunch_break:   jsonb { "active": true, "start": "12:00", "end": "13:00" }
--   booking_blocks:                 tablo (store_slug, block_date, start_time, end_time)
-- ============================================================================

BEGIN;

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
  -- V-19: Çalışma saati / öğle arası / blok kontrolleri için değişkenler
  v_dow text;
  v_hours jsonb;
  v_lunch_active boolean;
  v_lunch_start time;
  v_lunch_end time;
  v_new_time_time time;
  v_blocked boolean;
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

  -- V-19: Çalışma saati kontrolü
  v_dow := extract(isodow FROM p_new_time)::text;
  v_hours := v_settings.working_hours->v_dow;

  IF v_hours IS NULL OR NOT (v_hours->>'active')::boolean THEN
    RAISE EXCEPTION 'OUTSIDE_WORKING_HOURS';
  END IF;

  -- V-19: Öğle arası kontrolü
  v_lunch_active := (v_settings.lunch_break->>'active')::boolean;
  IF v_lunch_active THEN
    v_lunch_start := (v_settings.lunch_break->>'start')::time;
    v_lunch_end := (v_settings.lunch_break->>'end')::time;
    v_new_time_time := p_new_time::time;

    IF v_new_time_time >= v_lunch_start AND v_new_time_time < v_lunch_end THEN
      RAISE EXCEPTION 'DURING_LUNCH_BREAK';
    END IF;
  END IF;

  -- V-19: Bloke edilmiş zaman dilimi kontrolü
  SELECT EXISTS (
    SELECT 1 FROM public.booking_blocks
    WHERE store_slug = v_appt.store_slug
      AND block_date = p_new_time::date
      AND (
        (start_time IS NULL AND end_time IS NULL) OR
        (p_new_time::time >= start_time AND p_new_time::time < end_time)
      )
  ) INTO v_blocked;

  IF v_blocked THEN
    RAISE EXCEPTION 'TIME_SLOT_BLOCKED';
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

COMMENT ON FUNCTION public.request_appointment_reschedule(text, timestamptz) IS
  'Müşteri randevuyu erteleme talebi oluşturur. Token ile yetkilendirilir. Çalışma saati, öğle arası, blok ve kapasite kontrolleri yapılır (V-19 fix).';

COMMIT;