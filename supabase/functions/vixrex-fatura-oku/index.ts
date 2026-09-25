// Fatura görüntüsünden ürün satırlarını çıkarır.
// Secrets: OPENAI_API_KEY, OPENAI_FATURA_MODEL (istege bagli)
//
// Bu islev yalniz OKUR. Veritabanina yazmaz, urun olusturmaz, gorunurluk
// acmaz. Cikan satirlari Next.js tarafi esnafa gosterir; esnaf fiyat girip
// onaylamadan hicbir urun vitrine girmez.
//
// Alis fiyati asla satis fiyati olarak dondurulmez: ayri alan (alisBirimFiyat).

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const MAKS_GORUNTU_BAYT = 8 * 1024 * 1024;
const MAKS_SATIR = 100;

type FaturaSatiri = {
  model: string;
  ad: string;
  barkod: string;
  varyant: string;
  beden: string;
  adet: number | null;
  alisBirimFiyat: number | null;
  satirToplam: number | null;
  guven: number;
};

type FaturaSonucu = {
  satirlar: FaturaSatiri[];
  belgeToplami: number | null;
  belgeAdedi: number | null;
  tedarikci: string;
};

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
      return json({ hata: 'Fatura görüntüsü bulunamadı.' }, 400);
    }
    if (dataUrl.length > MAKS_GORUNTU_BAYT) {
      return json({ hata: 'Fatura görüntüsü çok büyük.' }, 413);
    }

    const apiKey = Deno.env.get('OPENAI_API_KEY') ?? '';
    if (!apiKey) {
      return json({ hata: 'Fatura okuyucu şu an hazır değil.' }, 503);
    }

    const cevap = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: Deno.env.get('OPENAI_FATURA_MODEL') ?? 'gpt-4.1-mini',
        temperature: 0,
        max_tokens: 4000,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: SISTEM_TALIMATI },
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: 'Bu fatura/irsaliye görüntüsündeki ürün satırlarını çıkar.',
              },
              { type: 'image_url', image_url: { url: dataUrl, detail: 'high' } },
            ],
          },
        ],
      }),
    });

    if (!cevap.ok) {
      console.error('fatura-oku OpenAI failed:', cevap.status);
      return json({ hata: 'Fatura şu an okunamadı. Tekrar dene.' }, 502);
    }

    const govde = await cevap.json();
    const icerik = govde.choices?.[0]?.message?.content;
    const sonuc = temizle(JSON.parse(String(icerik ?? '{}')));
    return json(sonuc);
  } catch (hata) {
    console.error('vixrex-fatura-oku failed:', hata);
    return json({ hata: 'Fatura şu an okunamadı. Tekrar dene.' }, 500);
  }
});

const SISTEM_TALIMATI = [
  'Sen bir fatura/irsaliye okuyucusun. Görüntüdeki ÜRÜN SATIRLARINI çıkarırsın.',
  'Yalnız görüntüde GERÇEKTEN YAZAN bilgiyi yaz. Tahmin etme, tamamlama, uydurma.',
  'Okuyamadığın alanı boş bırak ("" veya null) ve o satırın guven değerini düşür.',
  'Başlık, toplam, KDV, iskonto, adres, imza ve dipnot satırlarını ürün sayma.',
  'Yanıt yalnız şu JSON olsun:',
  '{"satirlar":[{"model":string,"ad":string,"barkod":string,"varyant":string,',
  '"beden":string,"adet":number|null,"alisBirimFiyat":number|null,',
  '"satirToplam":number|null,"guven":number}],"belgeToplami":number|null,',
  '"belgeAdedi":number|null,"tedarikci":string}',
  'model: ürün/stok kodu (ör. ELT1302). Yoksa "".',
  'barkod: 8-14 haneli sayı. Yoksa "".',
  'varyant: renk gibi ayırt edici değer. beden: L, XL, 4, 8-10 Yaş gibi.',
  'adet: fatura satırındaki miktar. alisBirimFiyat: birim alış fiyatı.',
  'satirToplam: o satırın tutarı. Sayıları nokta ayraçlı ondalık olarak ver (137.5).',
  'guven: 0 ile 1 arası; satırın tüm alanlarını ne kadar net okuduğun.',
  'belgeToplami ve belgeAdedi: belgenin kendi genel toplamı ve toplam adedi.',
  'tedarikci: faturayı kesen firmanın adı; okunamıyorsa "".',
].join(' ');

function temizle(ham: unknown): FaturaSonucu {
  const kok = (ham ?? {}) as Record<string, unknown>;
  const gelen = Array.isArray(kok.satirlar) ? kok.satirlar : [];

  const satirlar = gelen
    .slice(0, MAKS_SATIR)
    .map((satir) => satirTemizle(satir))
    .filter((satir): satir is FaturaSatiri => satir !== null);

  return {
    satirlar,
    belgeToplami: sayi(kok.belgeToplami),
    belgeAdedi: sayi(kok.belgeAdedi),
    tedarikci: metin(kok.tedarikci, 120),
  };
}

function satirTemizle(ham: unknown): FaturaSatiri | null {
  const satir = (ham ?? {}) as Record<string, unknown>;
  const ad = metin(satir.ad, 200);
  const model = metin(satir.model, 60);
  const barkodHam = metin(satir.barkod, 20).replace(/\D/g, '');

  // Adı da kodu da olmayan satır ürün değildir.
  if (!ad && !model) return null;

  const guvenHam = sayi(satir.guven);
  const guven = guvenHam === null ? 0.5 : Math.min(1, Math.max(0, guvenHam));

  return {
    model,
    ad,
    barkod: barkodHam.length >= 8 && barkodHam.length <= 14 ? barkodHam : '',
    varyant: metin(satir.varyant, 60),
    beden: metin(satir.beden, 40),
    adet: pozitifSayi(satir.adet),
    alisBirimFiyat: pozitifSayi(satir.alisBirimFiyat),
    satirToplam: pozitifSayi(satir.satirToplam),
    guven,
  };
}

function metin(value: unknown, maks: number): string {
  if (typeof value !== 'string') return '';
  return value.trim().replace(/\s+/g, ' ').slice(0, maks);
}

function sayi(value: unknown): number | null {
  if (typeof value === 'number') return Number.isFinite(value) ? value : null;
  if (typeof value !== 'string') return null;
  const temiz = value.trim().replace(/\s/g, '').replace(/\./g, '').replace(',', '.');
  const n = Number(temiz);
  return Number.isFinite(n) ? n : null;
}

function pozitifSayi(value: unknown): number | null {
  const n = sayi(value);
  if (n === null || n <= 0) return null;
  return n;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
