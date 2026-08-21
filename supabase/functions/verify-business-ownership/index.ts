import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const ALLOWED_ORIGIN = 'https://vixrex-app.vercel.app';
const BUSINESS_SCOPE_ERROR = 'Google Business Profile erişim izni gerekli.';
const corsHeaders = {
  'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type GoogleAccount = { name?: string };

interface GoogleLocation {
  name?: string;
  phoneNumbers?: {
    primaryPhone?: string;
    additionalPhones?: string[];
  };
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return originAllowed(req) ? new Response('ok', { headers: corsHeaders }) : json(
      { error: 'İzin verilmeyen kaynak' },
      403,
    );
  }
  if (req.method !== 'POST') return json({ error: 'Yöntem desteklenmiyor' }, 405);
  if (!originAllowed(req)) return json({ error: 'İzin verilmeyen kaynak' }, 403);

  try {
    const authorization = req.headers.get('Authorization');
    if (!authorization) return json({ error: 'Oturum gerekli' }, 401);

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return json({ error: 'Doğrulama servisi yapılandırılmamış' }, 503);
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
    });
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) return json({ error: 'Oturum gerekli' }, 401);

    const payload = await req.json().catch(() => null);
    const storeId = String(payload?.storeId ?? '').trim();
    const accessToken = String(payload?.accessToken ?? '').trim();
    if (!/^[0-9a-f-]{36}$/i.test(storeId) || !accessToken || accessToken.length > 8192) {
      return json({ error: 'Geçersiz doğrulama isteği' }, 400);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);
    const { data: store, error: storeError } = await admin
      .from('stores')
      .select('id,name,phone,whatsapp,business_verified_at')
      .eq('id', storeId)
      .eq('user_id', userData.user.id)
      .eq('is_published', true)
      .maybeSingle();
    if (storeError) throw storeError;
    if (!store) return json({ error: 'Yayınlanmış vitrin bulunamadı' }, 404);
    if (store.business_verified_at) {
      return json({ verified: true, storeName: store.name });
    }

    const storePhones = [store.phone, store.whatsapp]
      .map(normalizePhone)
      .filter((phone): phone is string => Boolean(phone));
    if (storePhones.length === 0) {
      return json(
        { error: 'Vitrindeki telefon veya WhatsApp numarası eksik' },
        422,
      );
    }

    const accounts = await listAccounts(accessToken);
    let matchingLocation: GoogleLocation | null = null;
    for (const account of accounts) {
      if (!account.name) continue;
      const locations = await listLocations(accessToken, account.name);
      matchingLocation = locations.find((location) =>
        locationPhones(location).some((phone) => storePhones.includes(phone))
      ) ?? null;
      if (matchingLocation) break;
    }

    if (!matchingLocation?.name) {
      return json(
        { error: 'Google Business Profile telefonuyla vitrin telefonu eşleşmedi' },
        422,
      );
    }

    const { error: updateError } = await admin
      .from('stores')
      .update({
        business_verified_at: new Date().toISOString(),
        business_verification_method: 'google_business_profile',
        google_business_location_name: matchingLocation.name,
      })
      .eq('id', store.id)
      .eq('user_id', userData.user.id);
    if (updateError?.code === '23505') {
      return json(
        { error: 'Bu Google işletme profili başka bir vitrine bağlı' },
        409,
      );
    }
    if (updateError) throw updateError;
    return json({ verified: true, storeName: store.name });
  } catch (error) {
    if (error instanceof GoogleApiError) {
      console.error('[verify-business-ownership] Google API:', error.status);
      return json({ error: BUSINESS_SCOPE_ERROR }, error.status === 401 ? 401 : 403);
    }
    console.error('[verify-business-ownership] beklenmeyen hata:', error);
    return json({ error: 'İşletme doğrulanamadı. Lütfen tekrar deneyin.' }, 500);
  }
});

function originAllowed(req: Request): boolean {
  return [null, ALLOWED_ORIGIN].includes(req.headers.get('Origin'));
}

function normalizePhone(value: unknown): string | null {
  const digits = String(value ?? '').replace(/\D/g, '');
  return digits.length >= 10 ? digits.slice(-10) : null;
}

function locationPhones(location: GoogleLocation): string[] {
  return [
    location.phoneNumbers?.primaryPhone,
    ...(location.phoneNumbers?.additionalPhones ?? []),
  ].map(normalizePhone).filter((phone): phone is string => Boolean(phone));
}

async function listAccounts(accessToken: string): Promise<GoogleAccount[]> {
  const body = await googleJson(
    'https://mybusinessaccountmanagement.googleapis.com/v1/accounts',
    accessToken,
  );
  return Array.isArray(body.accounts) ? body.accounts : [];
}

async function listLocations(
  accessToken: string,
  accountName: string,
): Promise<GoogleLocation[]> {
  const locations: GoogleLocation[] = [];
  let pageToken = '';
  for (let page = 0; page < 10; page += 1) {
    const query = new URLSearchParams({
      readMask: 'name,phoneNumbers',
      pageSize: '100',
      ...(pageToken ? { pageToken } : {}),
    });
    const body = await googleJson(
      `https://mybusinessbusinessinformation.googleapis.com/v1/${accountName}/locations?${query}`,
      accessToken,
    );
    if (Array.isArray(body.locations)) locations.push(...body.locations);
    pageToken = String(body.nextPageToken ?? '');
    if (!pageToken) break;
  }
  return locations;
}

async function googleJson(url: string, accessToken: string): Promise<any> {
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!response.ok) throw new GoogleApiError(response.status);
  return await response.json();
}

class GoogleApiError extends Error {
  constructor(readonly status: number) {
    super('Google API request failed');
  }
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
