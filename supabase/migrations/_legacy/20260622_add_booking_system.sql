-- Migration: Hairdresser and Beauty Appointment Booking System

-- 1. Create Tables
create table if not exists public.booking_settings (
  store_slug text primary key references public.stores(slug) on delete cascade,
  is_enabled boolean default false,
  capacity int default 1 constraint check_capacity check (capacity >= 1 and capacity <= 5),
  working_hours jsonb default '{
    "1": {"start": "09:00", "end": "19:00", "active": true},
    "2": {"start": "09:00", "end": "19:00", "active": true},
    "3": {"start": "09:00", "end": "19:00", "active": true},
    "4": {"start": "09:00", "end": "19:00", "active": true},
    "5": {"start": "09:00", "end": "19:00", "active": true},
    "6": {"start": "09:00", "end": "16:00", "active": true},
    "7": {"start": "00:00", "end": "00:00", "active": false}
  }'::jsonb,
  lunch_break jsonb default '{"start": "12:00", "end": "13:00", "active": true}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.booking_blocks (
  id uuid primary key default gen_random_uuid(),
  store_slug text not null references public.stores(slug) on delete cascade,
  block_date date not null,
  start_time time without time zone,
  end_time time without time zone,
  reason text,
  created_at timestamptz default now()
);

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  store_slug text not null references public.stores(slug) on delete cascade,
  customer_name text not null,
  customer_phone text not null,
  customer_notes text,
  service_title text not null,
  service_price text,
  service_duration int not null constraint check_duration check (service_duration >= 15 and service_duration <= 240),
  appointment_time timestamptz not null,
  status text default 'pending' constraint check_status check (status in ('pending', 'confirmed', 'rejected', 'cancelled_by_customer', 'cancelled_by_store', 'expired')),
  token_hash text not null unique,
  created_at timestamptz default now(),
  expires_at timestamptz not null
);

create table if not exists public.appointment_reschedule_requests (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  requested_time timestamptz not null,
  status text default 'pending' constraint check_reschedule_status check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz default now()
);

-- Indexes for performance
create index if not exists idx_appointments_store_time on public.appointments(store_slug, appointment_time);
create index if not exists idx_appointments_token_hash on public.appointments(token_hash);
create index if not exists idx_booking_blocks_store_date on public.booking_blocks(store_slug, block_date);

-- Enable RLS
alter table public.booking_settings enable row level security;
alter table public.booking_blocks enable row level security;
alter table public.appointments enable row level security;
alter table public.appointment_reschedule_requests enable row level security;

-- 2. RLS Policies

-- booking_settings
create policy "Allow public read booking settings" on public.booking_settings
  for select to anon, authenticated using (true);

create policy "Allow owners to insert booking settings" on public.booking_settings
  for insert to authenticated with check (
    exists (select 1 from public.stores s where s.slug = store_slug and s.user_id = auth.uid())
  );

create policy "Allow owners to update booking settings" on public.booking_settings
  for update to authenticated using (
    exists (select 1 from public.stores s where s.slug = store_slug and s.user_id = auth.uid())
  );

-- booking_blocks
create policy "Allow public read booking blocks" on public.booking_blocks
  for select to anon, authenticated using (true);

create policy "Allow owners to manage booking blocks" on public.booking_blocks
  for all to authenticated using (
    exists (select 1 from public.stores s where s.slug = store_slug and s.user_id = auth.uid())
  );

-- appointments
create policy "Allow owners select appointments" on public.appointments
  for select to authenticated using (
    exists (select 1 from public.stores s where s.slug = store_slug and s.user_id = auth.uid())
  );

create policy "Allow owners update appointments" on public.appointments
  for update to authenticated using (
    exists (select 1 from public.stores s where s.slug = store_slug and s.user_id = auth.uid())
  );

-- appointment_reschedule_requests
create policy "Allow owners select reschedule requests" on public.appointment_reschedule_requests
  for select to authenticated using (
    exists (
      select 1 from public.appointments a
      join public.stores s on s.slug = a.store_slug
      where a.id = appointment_id and s.user_id = auth.uid()
    )
  );

create policy "Allow owners update reschedule requests" on public.appointment_reschedule_requests
  for update to authenticated using (
    exists (
      select 1 from public.appointments a
      join public.stores s on s.slug = a.store_slug
      where a.id = appointment_id and s.user_id = auth.uid()
    )
  );

-- 3. PL/pgSQL Helper Functions

-- Masking function: Ahmet Yılmaz -> A*** Y***
create or replace function public.mask_appointment_name(p_name text)
returns text
language plpgsql
immutable
as $$
declare
  v_parts text[];
  v_result text[] := '{}';
  v_part text;
begin
  v_parts := regexp_split_to_array(trim(p_name), '\s+');
  foreach v_part in array v_parts loop
    if length(v_part) > 0 then
      v_result := array_append(v_result, left(v_part, 1) || '***');
    end if;
  end loop;
  return array_to_string(v_result, ' ');
end;
$$;

-- 4. RPC Functions (Security Definer with search_path)

-- Calculate available 15-minute slots for a given store and date
create or replace function public.get_public_booking_slots(p_store_slug text, p_date date)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
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
begin
  -- Fetch booking settings
  select * into v_settings from public.booking_settings where store_slug = p_store_slug;
  if not found or not v_settings.is_enabled then
    return '[]'::jsonb;
  end if;

  v_capacity := v_settings.capacity;

  -- Get DOW working hours (1 = Monday, 7 = Sunday)
  v_dow := extract(isodow from p_date)::text;
  v_hours := v_settings.working_hours->v_dow;

  if v_hours is null or not (v_hours->>'active')::boolean then
    return '[]'::jsonb;
  end if;

  v_start_str := v_hours->>'start';
  v_end_str := v_hours->>'end';

  -- Parse lunch break
  v_lunch_active := (v_settings.lunch_break->>'active')::boolean;
  if v_lunch_active then
    v_lunch_start := (v_settings.lunch_break->>'start')::time;
    v_lunch_end := (v_settings.lunch_break->>'end')::time;
  end if;

  -- Build start and end timestamps (assume server timezone for booking slot calculations)
  -- To keep timezone logic simple and stable, represent slots in local time context
  v_slot := (p_date::text || ' ' || v_start_str)::timestamp with time zone;
  v_end_limit := (p_date::text || ' ' || v_end_str)::timestamp with time zone;

  -- Loop through day in 15-minute intervals
  while v_slot < v_end_limit loop
    v_slot_time := v_slot::time;
    v_slot_time_str := to_char(v_slot_time, 'HH24:MI');

    -- 1. Check Lunch Break
    if v_lunch_active and v_slot_time >= v_lunch_start and v_slot_time < v_lunch_end then
      v_blocked := true;
    else
      -- 2. Check Custom Booking Blocks
      select exists (
        select 1 from public.booking_blocks
        where store_slug = p_store_slug
          and block_date = p_date
          and (
            (start_time is null and end_time is null) or
            (v_slot_time >= start_time and v_slot_time < end_time)
          )
      ) into v_blocked;
    end if;

    if not v_blocked then
      -- 3. Calculate Overlapping Appointments
      -- An active appointment overlaps if:
      -- appt.appointment_time <= slot AND slot < appt.appointment_time + appt.service_duration
      v_active_appts_count := 0;
      v_confirmed_names := '{}'::text[];
      v_has_pending := false;

      for v_appt in (
        select customer_name, status, service_duration, appointment_time
        from public.appointments
        where store_slug = p_store_slug
          and status in ('pending', 'confirmed')
          and (status = 'confirmed' or expires_at > now())
          and appointment_time <= v_slot
          and v_slot < appointment_time + (service_duration || ' minutes')::interval
      ) loop
        v_active_appts_count := v_active_appts_count + 1;
        if v_appt.status = 'confirmed' then
          v_confirmed_names := array_append(v_confirmed_names, public.mask_appointment_name(v_appt.customer_name));
        else
          v_has_pending := true;
        end if;
      end loop;

      v_slot_obj := jsonb_build_object(
        "time", v_slot_time_str,
        "capacity_total", v_capacity,
        "capacity_used", v_active_appts_count,
        "slots_left", greatest(0, v_capacity - v_active_appts_count),
        "confirmed_names", to_jsonb(v_confirmed_names),
        "has_pending", v_has_pending
      );

      v_slots_result := v_slots_result || jsonb_build_array(v_slot_obj);
    end if;

    v_slot := v_slot + interval '15 minutes';
  end loop;

  return v_slots_result;
end;
$$;

-- Create a secure appointment request
create or replace function public.create_appointment_request(
  p_store_slug text,
  p_customer_name text,
  p_customer_phone text,
  p_customer_notes text,
  p_service_title text,
  p_service_price text,
  p_service_duration int,
  p_appointment_time timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
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
begin
  -- 1. Anti-spam check (maximum 5 appointments per phone number in 24 hours)
  select count(*) into v_daily_count
  from public.appointments
  where customer_phone = p_customer_phone
    and created_at > now() - interval '24 hours';
    
  if v_daily_count >= 5 then
    raise exception 'DAILY_LIMIT_EXCEEDED';
  end if;

  -- 2. Acquire transaction-level advisory lock on store to prevent race conditions
  select pg_try_advisory_xact_lock(hashtext(p_store_slug)) into v_lock_ok;
  if not v_lock_ok then
    raise exception 'STORE_BUSY_TRY_AGAIN';
  end if;

  -- 3. Fetch booking settings
  select * into v_settings from public.booking_settings where store_slug = p_store_slug;
  if not found or not v_settings.is_enabled then
    raise exception 'BOOKING_DISABLED';
  end if;

  -- 4. Verify working hours constraints
  v_dow := extract(isodow from p_appointment_time)::text;
  v_hours := v_settings.working_hours->v_dow;
  if v_hours is null or not (v_hours->>'active')::boolean then
    raise exception 'STORE_CLOSED_ON_THIS_DAY';
  end if;

  v_start_time := (v_hours->>'start')::time;
  v_end_time := (v_hours->>'end')::time;
  v_slot_time := p_appointment_time::time;

  if v_slot_time < v_start_time or v_slot_time >= v_end_time then
    raise exception 'OUTSIDE_WORKING_HOURS';
  end if;

  -- Check Lunch Break
  v_lunch_active := (v_settings.lunch_break->>'active')::boolean;
  if v_lunch_active then
    v_lunch_start := (v_settings.lunch_break->>'start')::time;
    v_lunch_end := (v_settings.lunch_break->>'end')::time;
    if v_slot_time >= v_lunch_start and v_slot_time < v_lunch_end then
      raise exception 'LUNCH_BREAK_BLOCK';
    end if;
  end if;

  -- Check Custom Blocks
  select exists (
    select 1 from public.booking_blocks
    where store_slug = p_store_slug
      and block_date = p_appointment_time::date
      and (
        (start_time is null and end_time is null) or
        (v_slot_time >= start_time and v_slot_time < end_time)
      )
  ) into v_blocked;
  if v_blocked then
    raise exception 'DATE_TIME_BLOCKED';
  end if;

  -- 5. Calculate and check capacity over the appointment's entire duration
  v_appt_end := p_appointment_time + (p_service_duration || ' minutes')::interval;
  v_slot := p_appointment_time;

  while v_slot < v_appt_end loop
    select count(*) into v_active_appts_count
    from public.appointments
    where store_slug = p_store_slug
      and status in ('pending', 'confirmed')
      and (status = 'confirmed' or expires_at > now())
      and appointment_time <= v_slot
      and v_slot < appointment_time + (service_duration || ' minutes')::interval;

    if v_active_appts_count >= v_settings.capacity then
      raise exception 'CAPACITY_FULL';
    end if;

    v_slot := v_slot + interval '15 minutes';
  end loop;

  -- 6. Generate Token and Save
  v_plaintext_token := encode(gen_random_bytes(16), 'hex');
  v_token_hash := encode(sha256(v_plaintext_token::bytea), 'hex');
  v_appt_id := gen_random_uuid();

  insert into public.appointments (
    id,
    store_slug,
    customer_name,
    customer_phone,
    customer_notes,
    service_title,
    service_price,
    service_duration,
    appointment_time,
    status,
    token_hash,
    expires_at
  ) values (
    v_appt_id,
    p_store_slug,
    trim(p_customer_name),
    trim(p_customer_phone),
    trim(p_customer_notes),
    trim(p_service_title),
    trim(p_service_price),
    p_service_duration,
    p_appointment_time,
    'pending',
    v_token_hash,
    now() + interval '2 hours'
  );

  return jsonb_build_object(
    'appointment_id', v_appt_id,
    'token', v_plaintext_token
  );
end;
$$;

-- Securely fetch appointment details by token
create or replace function public.get_appointment_by_token(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_token_hash text;
  v_appt record;
  v_reschedule record;
  v_store_name text;
begin
  v_token_hash := encode(sha256(p_token::bytea), 'hex');

  select a.*, s.name as store_name
  into v_appt
  from public.appointments a
  join public.stores s on s.slug = a.store_slug
  where a.token_hash = v_token_hash;

  if not found then
    return null;
  end if;

  select * into v_reschedule
  from public.appointment_reschedule_requests
  where appointment_id = v_appt.id and status = 'pending'
  order by created_at desc
  limit 1;

  return jsonb_build_object(
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
    'reschedule_request', case
      when v_reschedule.id is not null then jsonb_build_object(
        'id', v_reschedule.id,
        'requested_time', v_reschedule.requested_time,
        'status', v_reschedule.status
      )
      else null
    end
  );
end;
$$;

-- Cancel appointment by customer token
create or replace function public.cancel_appointment_by_token(p_token text)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_token_hash text;
begin
  v_token_hash := encode(sha256(p_token::bytea), 'hex');

  update public.appointments
  set status = 'cancelled_by_customer'
  where token_hash = v_token_hash
    and status in ('pending', 'confirmed');

  return found;
end;
$$;

-- Request reschedule by customer token
create or replace function public.request_appointment_reschedule(p_token text, p_new_time timestamptz)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_token_hash text;
  v_appt public.appointments%rowtype;
  v_settings public.booking_settings%rowtype;
  v_appt_end timestamptz;
  v_slot timestamptz;
  v_active_appts_count int;
  v_lock_ok boolean;
begin
  v_token_hash := encode(sha256(p_token::bytea), 'hex');

  select * into v_appt from public.appointments where token_hash = v_token_hash;
  if not found or v_appt.status not in ('pending', 'confirmed') then
    raise exception 'APPOINTMENT_NOT_ACTIVE';
  end if;

  -- Lock store slug
  select pg_try_advisory_xact_lock(hashtext(v_appt.store_slug)) into v_lock_ok;
  if not v_lock_ok then
    raise exception 'STORE_BUSY_TRY_AGAIN';
  end if;

  -- Capacity check for the reschedule time slot
  select * into v_settings from public.booking_settings where store_slug = v_appt.store_slug;
  if not found or not v_settings.is_enabled then
    raise exception 'BOOKING_DISABLED';
  end if;

  v_appt_end := p_new_time + (v_appt.service_duration || ' minutes')::interval;
  v_slot := p_new_time;

  while v_slot < v_appt_end loop
    select count(*) into v_active_appts_count
    from public.appointments
    where store_slug = v_appt.store_slug
      and id <> v_appt.id -- Exclude self
      and status in ('pending', 'confirmed')
      and (status = 'confirmed' or expires_at > now())
      and appointment_time <= v_slot
      and v_slot < appointment_time + (service_duration || ' minutes')::interval;

    if v_active_appts_count >= v_settings.capacity then
      raise exception 'CAPACITY_FULL';
    end if;

    v_slot := v_slot + interval '15 minutes';
  end loop;

  -- Cancel existing pending reschedule requests
  update public.appointment_reschedule_requests
  set status = 'rejected'
  where appointment_id = v_appt.id and status = 'pending';

  -- Create new reschedule request
  insert into public.appointment_reschedule_requests (
    appointment_id,
    requested_time,
    status
  ) values (
    v_appt.id,
    p_new_time,
    'pending'
  );

  return true;
end;
$$;

-- Owner responds to appointment actions
create or replace function public.respond_to_appointment(
  p_appointment_id uuid,
  p_action text, -- 'confirm', 'reject'
  p_reschedule_action text -- 'approve', 'reject'
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_appt public.appointments%rowtype;
  v_resched public.appointment_reschedule_requests%rowtype;
  v_is_owner boolean;
begin
  -- Retrieve appointment
  select * into v_appt from public.appointments where id = p_appointment_id;
  if not found then
    raise exception 'APPOINTMENT_NOT_FOUND';
  end if;

  -- Owner authorization check
  select exists (
    select 1 from public.stores
    where slug = v_appt.store_slug
      and user_id = auth.uid()
  ) into v_is_owner;

  if not v_is_owner then
    raise exception 'UNAUTHORIZED';
  end if;

  -- Handle Action
  if p_action is not null then
    if p_action = 'confirm' then
      update public.appointments
      set status = 'confirmed', expires_at = '9999-12-31 23:59:59+00'::timestamptz
      where id = p_appointment_id;
    elsif p_action = 'reject' then
      update public.appointments
      set status = 'rejected'
      where id = p_appointment_id;
    else
      raise exception 'INVALID_ACTION';
    end if;
    return true;
  end if;

  -- Handle Reschedule Action
  if p_reschedule_action is not null then
    select * into v_resched
    from public.appointment_reschedule_requests
    where appointment_id = p_appointment_id and status = 'pending'
    order by created_at desc
    limit 1;

    if not found then
      raise exception 'NO_PENDING_RESCHEDULE';
    end if;

    if p_reschedule_action = 'approve' then
      update public.appointment_reschedule_requests
      set status = 'approved'
      where id = v_resched.id;

      update public.appointments
      set appointment_time = v_resched.requested_time,
          status = 'confirmed',
          expires_at = '9999-12-31 23:59:59+00'::timestamptz
      where id = p_appointment_id;

    elsif p_reschedule_action = 'reject' then
      update public.appointment_reschedule_requests
      set status = 'rejected'
      where id = v_resched.id;
    else
      raise exception 'INVALID_ACTION';
    end if;
    return true;
  end if;

  return false;
end;
$$;

-- Grant execution permissions
revoke execute on function public.get_public_booking_slots(text, date) from public;
grant execute on function public.get_public_booking_slots(text, date) to anon, authenticated;

revoke execute on function public.create_appointment_request(text, text, text, text, text, text, int, timestamptz) from public;
grant execute on function public.create_appointment_request(text, text, text, text, text, text, int, timestamptz) to anon, authenticated;

revoke execute on function public.get_appointment_by_token(text) from public;
grant execute on function public.get_appointment_by_token(text) to anon, authenticated;

revoke execute on function public.cancel_appointment_by_token(text) from public;
grant execute on function public.cancel_appointment_by_token(text) to anon, authenticated;

revoke execute on function public.request_appointment_reschedule(text, timestamptz) from public;
grant execute on function public.request_appointment_reschedule(text, timestamptz) to anon, authenticated;

revoke execute on function public.respond_to_appointment(uuid, text, text) from public;
grant execute on function public.respond_to_appointment(uuid, text, text) to authenticated;

notify pgrst, 'reload schema';
