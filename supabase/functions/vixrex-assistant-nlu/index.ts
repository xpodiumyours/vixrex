// Vixrex serbest metin alan önerisi.
// Secrets: OPENAI_API_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
// İstemci veritabanına doğrudan yazmaz: function yalnız öneri döner,
// Flutter onayı aldıktan sonra mevcut StoreEditorController ile kaydeder.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};
const maxInputLength = 500;
// OpenAI özelliği askıda: Function ve secret korunur, OpenAI çağrısı yapılmaz.
const assistantEnabled = false;

type AssistantField =
  | 'store_name'
  | 'whatsapp'
  | 'address'
  | 'description'
  | 'category';

type NluProposal = {
  field: AssistantField | null;
  value: string | null;
  reply: string;
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return json({ error: 'Yalnızca POST desteklenir.' }, 405);
  }
  if (!assistantEnabled) {
    return json({ error: 'Vixrex asistanı şu an bakımda.' }, 503);
  }

  try {
    const payload = await request.json();
    const input = String(payload.input ?? '').trim();
    const clientId = String(payload.client_id ?? '').trim();
    const allowedCategories = Array.isArray(payload.allowed_categories)
      ? payload.allowed_categories
          .map((item: unknown) => {
            const category = item as { id?: unknown; label?: unknown };
            return `${String(category.id ?? '')}:${String(category.label ?? '')}`;
          })
          .filter((item: string) => item !== ':')
          .join(', ')
      : '';

    if (!input || !clientId || input.length > maxInputLength) {
      return json({ error: 'Geçersiz istek.' }, 400);
    }

    const clientKey = await hashClientKey(
      `${request.headers.get('x-forwarded-for') ?? 'unknown'}:${clientId}`,
    );
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );
    const { data: limitData, error: limitError } = await supabase.rpc(
      'consume_assistant_request',
      { p_client_key: clientKey, p_max_requests: 6 },
    );
    if (limitError) throw limitError;

    const rateLimit = Array.isArray(limitData) ? limitData[0] : limitData;
    if (!rateLimit?.allowed) {
      return json(
        {
          error: 'Bir dakika içinde çok fazla mesaj gönderdin. Lütfen biraz bekle.',
          retry_after_seconds: rateLimit?.retry_after_seconds ?? 60,
        },
        429,
      );
    }

    const apiKey = Deno.env.get('OPENAI_API_KEY') ?? '';
    if (!apiKey) {
      return json({ error: 'Asistan şu an hazır değil.' }, 503);
    }

    const openAiResponse = await fetch(
      'https://api.openai.com/v1/chat/completions',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: Deno.env.get('OPENAI_MODEL') ?? 'gpt-4.1-mini',
          temperature: 0,
          max_tokens: 220,
          response_format: { type: 'json_object' },
          messages: [
            {
              role: 'system',
              content: [
                'Sen Vixrex dijital vitrin asistanısın.',
                'Kullanıcının tek bir mesajından yalnızca şu alanlardan birini çıkar:',
                'store_name, whatsapp, address, description, category.',
                `Kategori için yalnızca şu id değerlerinden birini kullan: ${allowedCategories || 'kategori çıkarma'}.`,
                'Yasal onay, kimlik, ödeme ve hassas kişisel veri isteme veya çıkarma.',
                'Yanıtın yalnız JSON olsun: {"field": string|null, "value": string|null, "reply": string}.',
                'Belirsizse field ve value null olsun; reply ile kısa bir netleştirme sorusu sor.',
                'Doğrudan kaydettiğini söyleme; kullanıcıdan onay istenecek.',
                'Türkçe, kısa yaz.',
              ].join(' '),
            },
            { role: 'user', content: input },
          ],
        }),
      },
    );
    if (!openAiResponse.ok) {
      console.error('OpenAI request failed:', openAiResponse.status);
      return json({ error: 'Asistan şu an yanıt veremiyor. Tekrar dene.' }, 502);
    }

    const responseJson = await openAiResponse.json();
    const content = responseJson.choices?.[0]?.message?.content;
    const proposal = validateProposal(JSON.parse(String(content ?? '{}')));
    return json({ proposal });
  } catch (error) {
    console.error('vixrex-assistant-nlu failed:', error);
    return json({ error: 'Asistan şu an yanıt veremiyor. Tekrar dene.' }, 500);
  }
});

async function hashClientKey(value: string) {
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

function validateProposal(value: unknown): NluProposal {
  const raw = value as Partial<NluProposal>;
  const allowedFields: readonly AssistantField[] = [
    'store_name',
    'whatsapp',
    'address',
    'description',
    'category',
  ];
  const field = allowedFields.includes(raw.field as AssistantField)
    ? (raw.field as AssistantField)
    : null;
  const fieldValue = typeof raw.value === 'string' ? raw.value.trim() : null;
  const reply = typeof raw.reply === 'string' && raw.reply.trim().length > 0
    ? raw.reply.trim().slice(0, 300)
    : 'Bunu vitrininde kullanmamı ister misin?';

  return {
    field: fieldValue ? field : null,
    value: fieldValue && field ? fieldValue.slice(0, 500) : null,
    reply,
  };
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
