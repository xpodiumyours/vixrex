import { readFile, writeFile, mkdir } from "node:fs/promises";
import { basename, extname } from "node:path";

const kullanim = `Kullanim:
  VIXREX_ORIGIN=https://... VIXREX_SLUG=... VIXREX_EDIT_TOKEN=... node tool/fatura_kabul.mjs <foto> [<foto>...]

Ortam degiskenleri zorunludur; anahtar dosyaya yazilmaz. Her fotograf gercek /api/fatura-oku ucundan gecer,
sure olculur, sonuc test-sonuc/fatura-kabul-<zaman>.json ve .md dosyalarina yazilir.
Hicbir urun olusturulmaz veya yayinlanmaz.`;

const origin = (process.env.VIXREX_ORIGIN ?? "").replace(/\/$/, "");
const slug = process.env.VIXREX_SLUG ?? "";
const editToken = process.env.VIXREX_EDIT_TOKEN ?? "";
const dosyalar = process.argv.slice(2);

if (!origin || !slug || !editToken || dosyalar.length === 0) {
  console.error(kullanim);
  process.exit(2);
}

const TURLER = { ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png", ".webp": "image/webp" };

async function tekFatura(yol) {
  const bayt = await readFile(yol);
  const tur = TURLER[extname(yol).toLowerCase()];
  if (!tur) return { dosya: basename(yol), hata: "Desteklenmeyen dosya turu" };

  const form = new FormData();
  form.set("slug", slug);
  form.set("editToken", editToken);
  form.set("dosya", new Blob([bayt], { type: tur }), basename(yol));

  const bas = Date.now();
  let cevap;
  try {
    cevap = await fetch(`${origin}/api/fatura-oku`, { method: "POST", body: form });
  } catch (hata) {
    return { dosya: basename(yol), hata: `Ag hatasi: ${hata instanceof Error ? hata.message : hata}` };
  }
  const sureMs = Date.now() - bas;
  const govde = await cevap.json().catch(() => null);
  if (!cevap.ok || !govde) {
    return { dosya: basename(yol), durum: cevap.status, sureMs, hata: govde?.hata ?? "Cevap okunamadi" };
  }

  const satirlar = (govde.satirlar ?? []).map((satir) => ({
    model: satir.model,
    ad: satir.ad,
    adet: satir.adet,
    marka: satir.marka ?? "",
    sonuc: satir.sonuc,
    kaynak: satir.katalog?.kaynak ?? "",
    firma: satir.katalog?.firma ?? "",
    gorselSayisi: satir.katalog?.gorseller?.length ?? 0,
    uyari: satir.uyari ?? "",
  }));

  return {
    dosya: basename(yol),
    durum: cevap.status,
    sureMs,
    tekrar: govde.tekrar === true,
    tedarikci: govde.tedarikci,
    tedarikciDijitalIz: govde.tedarikciDijitalIz
      ? {
          alan: govde.tedarikciDijitalIz.alan,
          dogrulama: govde.tedarikciDijitalIz.dogrulama?.guc ?? "",
        }
      : null,
    belge: govde.belge ?? null,
    belgeUyarisi: govde.belgeUyarisi ?? "",
    ayniAlisveris: (govde.ayniAlisveris ?? []).length,
    sonucOzeti: govde.sonucOzeti,
    satirSayisi: satirlar.length,
    satirlar,
  };
}

const sonuclar = [];
for (const yol of dosyalar) {
  sonuclar.push(await tekFatura(yol));
}

const zaman = new Date().toISOString().replace(/[:.]/g, "-");
await mkdir("test-sonuc", { recursive: true });
await writeFile(`test-sonuc/fatura-kabul-${zaman}.json`, JSON.stringify({ origin, sonuclar }, null, 2));

const md = [
  `# Fatura kabul olcumu — ${zaman}`,
  "",
  `Hedef: ${origin}. Yalniz OKUMA ve ESLESTIRME olculdu; urun olusturma, yayin ve gorunum ayrica elle dogrulanir.`,
  "",
  ...sonuclar.flatMap((s) => [
    `## ${s.dosya}`,
    s.hata
      ? `- HATA: ${s.hata}`
      : `- Sure: ${(s.sureMs / 1000).toFixed(1)} sn • Firma: ${s.tedarikci || "okunamadi"} • Satir: ${s.satirSayisi}`,
    s.sonucOzeti ? `- Sonuc: ${JSON.stringify(s.sonucOzeti)}` : "",
    s.belgeUyarisi ? `- Belge uyarisi: ${s.belgeUyarisi}` : "",
    ...(s.satirlar ?? []).map(
      (r) => `  - ${r.model || r.ad} • ${r.sonuc} • gorsel:${r.gorselSayisi}${r.uyari ? ` • ${r.uyari}` : ""}`,
    ),
    "",
  ]),
  "## Elle doğrulanacaklar (bu arac yapmaz)",
  "- [ ] Urun kartinin kalici kaydi, kapat-ac, ikinci cihaz",
  "- [ ] Tuketici vitrini ve urun detayinda gercek gorsel",
  "- [ ] Firma izni talebi ve cevabinin kart iliskisi",
].filter((satir) => satir !== "");
await writeFile(`test-sonuc/fatura-kabul-${zaman}.md`, md.join("\n"));

console.log(md.join("\n"));
process.exit(sonuclar.some((s) => s.hata) ? 1 : 0);
