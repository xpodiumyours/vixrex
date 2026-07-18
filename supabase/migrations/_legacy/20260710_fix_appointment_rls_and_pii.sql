-- Faz 1.2: PII Güvenliği & RLS Sıkılaştırma
-- Appointment politikalarını güçlendir, auth.uid() sarmalama ekle

-- ── Appointments ─────────────────────────────────────────────────

-- Mevcut politikaları temizle
DROP POLICY IF EXISTS "Allow owners select appointments" ON public.appointments;
DROP POLICY IF EXISTS "Allow owners update appointments" ON public.appointments;

-- Owner: kendi mağazasının appointment'larını görebilir (sarmalanmış auth.uid)
CREATE POLICY "Owners can view their store appointments"
ON public.appointments FOR SELECT TO authenticated
USING (
  (select auth.uid()) IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = appointments.store_slug
      AND s.user_id = (select auth.uid())
  )
);

-- Owner: appointment durumunu güncelleyebilir
CREATE POLICY "Owners can update their store appointments"
ON public.appointments FOR UPDATE TO authenticated
USING (
  (select auth.uid()) IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = appointments.store_slug
      AND s.user_id = (select auth.uid())
  )
)
WITH CHECK (
  (select auth.uid()) IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = appointments.store_slug
      AND s.user_id = (select auth.uid())
  )
);

-- Appointment insert: sadece RPC (create_appointment_request) üzerinden service_role ile yapılmalı
-- Anonim insert'i engelle
-- (Varsa eski insert politikasını kaldır)
DROP POLICY IF EXISTS "Allow anonymous appointment insert" ON public.appointments;
DROP POLICY IF EXISTS "Allow public insert appointments" ON public.appointments;

-- ── Reschedule Requests ──────────────────────────────────────────

DROP POLICY IF EXISTS "Allow owners select reschedule requests" ON public.appointment_reschedule_requests;
DROP POLICY IF EXISTS "Allow owners update reschedule requests" ON public.appointment_reschedule_requests;

CREATE POLICY "Owners can view reschedule requests"
ON public.appointment_reschedule_requests FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.appointments a
    JOIN public.stores s ON s.slug = a.store_slug
    WHERE a.id = appointment_reschedule_requests.appointment_id
      AND s.user_id = (select auth.uid())
  )
);

CREATE POLICY "Owners can update reschedule requests"
ON public.appointment_reschedule_requests FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.appointments a
    JOIN public.stores s ON s.slug = a.store_slug
    WHERE a.id = appointment_reschedule_requests.appointment_id
      AND s.user_id = (select auth.uid())
  )
);

-- ── Stores: auth.uid() sarmalama ────────────────────────────────

DROP POLICY IF EXISTS "Allow owners to insert stores" ON public.stores;
DROP POLICY IF EXISTS "Users can update their own stores" ON public.stores;

CREATE POLICY "Authenticated users can create stores"
ON public.stores FOR INSERT TO authenticated
WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Owners can update their stores"
ON public.stores FOR UPDATE TO authenticated
USING ((select auth.uid()) = user_id)
WITH CHECK ((select auth.uid()) = user_id);

-- ── Booking: auth.uid() sarmalama ───────────────────────────────

DROP POLICY IF EXISTS "Allow owners to insert booking settings" ON public.booking_settings;
DROP POLICY IF EXISTS "Allow owners to update booking settings" ON public.booking_settings;
DROP POLICY IF EXISTS "Allow owners to manage booking blocks" ON public.booking_blocks;

CREATE POLICY "Owners can insert booking settings"
ON public.booking_settings FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = booking_settings.store_slug
      AND s.user_id = (select auth.uid())
  )
);

CREATE POLICY "Owners can update booking settings"
ON public.booking_settings FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = booking_settings.store_slug
      AND s.user_id = (select auth.uid())
  )
);

CREATE POLICY "Owners can manage booking blocks"
ON public.booking_blocks FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = booking_blocks.store_slug
      AND s.user_id = (select auth.uid())
  )
);

-- ── Performance: index ekle (RLS sorguları için) ────────────────

CREATE INDEX IF NOT EXISTS idx_stores_user_id ON public.stores USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_store_slug ON public.appointments USING btree (store_slug);

NOTIFY pgrst, 'reload schema';
