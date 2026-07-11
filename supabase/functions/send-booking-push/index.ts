// Supabase Edge Function: randevu push'u OneSignal REST ile gönderir.
// Secrets: ONESIGNAL_APP_ID, ONESIGNAL_REST_API_KEY
// Body: { externalUserId, title, body, storeSlug, type? }

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return json({ error: 'Yetkisiz' }, 401);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseAnon = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    const userClient = createClient(supabaseUrl, supabaseAnon, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) {
      return json({ error: 'Oturum gerekli' }, 401);
    }

    const appId = Deno.env.get('ONESIGNAL_APP_ID') ?? '';
    const restKey = Deno.env.get('ONESIGNAL_REST_API_KEY') ?? '';
    if (!appId || !restKey) {
      return json(
        { error: 'OneSignal yapılandırması eksik', skipped: true },
        503,
      );
    }

    const payload = await req.json();
    const externalUserId = String(payload.externalUserId ?? '').trim();
    const title = String(payload.title ?? '').trim();
    const body = String(payload.body ?? '').trim();
    const storeSlug = String(payload.storeSlug ?? '').trim();
    const type = String(payload.type ?? 'booking').trim();

    if (!externalUserId || !title || !body || !storeSlug) {
      return json({ error: 'Eksik alanlar' }, 400);
    }

    // Güvenlik: yalnızca kendi external id'sine (auth.uid) gönderim
    if (externalUserId !== userData.user.id) {
      return json({ error: 'Hedef kullanıcı eşleşmiyor' }, 403);
    }

    const onesignalRes = await fetch(
      'https://api.onesignal.com/notifications',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          Authorization: `Key ${restKey}`,
        },
        body: JSON.stringify({
          app_id: appId,
          include_aliases: { external_id: [externalUserId] },
          target_channel: 'push',
          headings: { en: title, tr: title },
          contents: { en: body, tr: body },
          data: { type, storeSlug, slug: storeSlug },
        }),
      },
    );

    const onesignalJson = await onesignalRes.json().catch(() => ({}));
    if (!onesignalRes.ok) {
      return json(
        {
          error: 'OneSignal gönderimi başarısız',
          detail: onesignalJson,
        },
        502,
      );
    }

    return json({ ok: true, id: onesignalJson.id ?? null });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
