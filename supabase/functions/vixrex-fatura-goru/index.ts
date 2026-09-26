// Fatura/belge görüntüsünü OKUR — yorumlamaz, satır ayırmaz, karar vermez.
//
// Vixrex'in TEK okuma ucu. Telefon kamerası ve web'den yüklenen fotoğraf
// AYNI bu işlevi çağırır — iki ayrı "okuma beyni" olmaz.
//
// Sağlayıcı: Kilo Gateway (https://api.kilo.ai/api/gateway), OpenAI-uyumlu,
// ANAHTAR GEREKTİRMEZ (IP başına saatte 200 istek sınırı). Model
// "stepfun/step-3.7-flash:free" — Başak'ın aynı bedava zincirinde ölçülüp
// doğrulanmış aynı model, aynı istek biçimi.
//
// Yalnız HAM METNİ döner. Satırlara ayırma (kod/barkod/beden/fiyat)
// public_web/src/lib/faturaSatirAyikla.ts içinde, deterministik kodla
// yapılır — model bir kez daha "yorumlamasın" diye.

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const KILO_ADRESI = 'https://api.kilo.ai/api/gateway/chat/completions';
const KILO_MODELI = 'stepfun/step-3.7-flash:free';
const MAKS_GORUNTU_BAYT = 8 * 1024 * 1024;

// Başak'ta (tools/katalog.py) ölçülüp doğrulanmış aynı istem: modelden
// yalnız SATIR SATIR YAZIYI ister, yorum/başlık istemez.
const GORUNTU_SORUSU = [
  'Bu fotoğraf/iş dosyasındaki TÜM yazıyı satır satır aynen yaz.',
  'Açıklama yapma, yorum ekleme, düşünceni yazma — yalnız fotoğraftaki',
  'yazının kendisi olsun.',
  'Tablo varsa her ürün satırını TEK satırda yaz: kod, ürün adı, barkod,',
  'renk, beden, adet, birim fiyat, tutar — aralarında tek boşluk, satırı',
  'bölme.',
  'Sayıları ve kodları olduğu gibi kopyala.',
  "Alt toplamı da TEK satırda aynen yaz: 'Toplam: <adet> ad <tutar> TL'",
  '(sayılar fotoğraftaki gibi).',
  'Okuyamadığın yeri uydurma, boş bırak.',
].join(' ');

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return json({ hata: 'Yalnızca POST desteklenir.' }, 405);
  }

  try {
    const payload = await request.json();
    const dataUrl = String(payload.goruntu ?? '').trim();

    if (!dataUrl.startsWith('data:image/')) {
      return json({ hata: 'Görüntü bulunamadı.' }, 400);
    }
    if (dataUrl.length > MAKS_GORUNTU_BAYT) {
      return json({ hata: 'Görüntü çok büyük.' }, 413);
    }

    const kiloYaniti = await fetch(KILO_ADRESI, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      // Kilo'nun ücretsiz uçları kimlik doğrulama istemez — Authorization
      // başlığı hiç gönderilmez (göndersek bile anonim erişimi bozmaz,
      // ama Başak'taki desenle tutarlı olsun diye hiç eklenmiyor).
      body: JSON.stringify({
        model: KILO_MODELI,
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: GORUNTU_SORUSU },
              { type: 'image_url', image_url: { url: dataUrl } },
            ],
          },
        ],
      }),
    });

    if (!kiloYaniti.ok) {
      console.error('vixrex-fatura-goru: Kilo failed:', kiloYaniti.status);
      return json(
        { hata: 'Görüntü şu an okunamadı. Tekrar dene.' },
        kiloYaniti.status === 429 ? 429 : 502,
      );
    }

    const govde = await kiloYaniti.json();
    const metin = String(govde?.choices?.[0]?.message?.content ?? '').trim();

    if (!metin) {
      return json({ hata: 'Fotoğrafta yazı bulunamadı.' }, 422);
    }

    return json({ tamam: true, yazi: metin, model: KILO_MODELI });
  } catch (hata) {
    console.error('vixrex-fatura-goru failed:', hata);
    return json({ hata: 'Görüntü şu an okunamadı. Tekrar dene.' }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
