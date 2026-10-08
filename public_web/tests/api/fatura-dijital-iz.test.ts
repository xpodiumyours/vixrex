import { createHash } from "node:crypto";
import { describe, expect, it } from "vitest";
import { pdfKatalogGorseliniOku, hamGet } from "@/lib/faturaDijitalIz";
import { kaynakGorseliniDogrula } from "@/lib/faturaGorsel";

const resolveHost = async () => ["8.8.8.8"];
const pdfKaynak = "https://resmi.example/katalog.pdf";

function gercekPdf(metin = "MODEL: ABC123 Cotton shirt"): Uint8Array {
  const resim = Buffer.alloc(1200 * 1200 * 3);
  for (let i = 0; i < resim.length; i++) resim[i] = (i * 37) % 255;
  const icerik = Buffer.from(`BT /F1 18 Tf 40 700 Td (${metin}) Tj ET q 400 0 0 400 40 250 cm /Im1 Do Q`);
  const nesneler = [
    Buffer.from("<< /Type /Catalog /Pages 2 0 R >>"),
    Buffer.from("<< /Type /Pages /Kids [3 0 R] /Count 1 >>"),
    Buffer.from("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 600 800] /Resources << /Font << /F1 4 0 R >> /XObject << /Im1 5 0 R >> >> /Contents 6 0 R >>"),
    Buffer.from("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"),
    Buffer.concat([Buffer.from(`<< /Type /XObject /Subtype /Image /Width 1200 /Height 1200 /ColorSpace /DeviceRGB /BitsPerComponent 8 /Length ${resim.length} >>\nstream\n`), resim, Buffer.from("\nendstream")]),
    Buffer.concat([Buffer.from(`<< /Length ${icerik.length} >>\nstream\n`), icerik, Buffer.from("\nendstream")]),
  ];
  const parcalar = [Buffer.from("%PDF-1.4\n")];
  const offsetler: number[] = [];
  let offset = parcalar[0].length;
  nesneler.forEach((nesne, i) => {
    offsetler.push(offset);
    const parca = Buffer.concat([Buffer.from(`${i + 1} 0 obj\n`), nesne, Buffer.from("\nendobj\n")]);
    parcalar.push(parca);
    offset += parca.length;
  });
  parcalar.push(Buffer.from(`xref\n0 7\n0000000000 65535 f \n` +
    offsetler.map((n) => `${String(n).padStart(10, "0")} 00000 n \n`).join("") +
    `trailer\n<< /Size 7 /Root 1 0 R >>\nstartxref\n${offset}\n%%EOF`));
  return new Uint8Array(Buffer.concat(parcalar));
}

function pdfFetch(pdf: Uint8Array) {
  return async (input: string) => input === pdfKaynak
    ? new Response(pdf.slice(), { headers: { "content-type": "application/pdf" } })
    : new Response("{}", { status: 404 });
}

describe("resmi PDF katalog goruntusu", () => {
  it("gercek PDF gomulu resmi kalite yoluna tasir", async () => {
    const pdf = gercekPdf();
    const fetcher = pdfFetch(pdf);
    const ozet = createHash("sha256").update(pdf).digest("hex");
    const adres = `${pdfKaynak}#vixrex-page=1&vixrex-image=0&vixrex-sha256=${ozet}`;
    const bayt = await pdfKatalogGorseliniOku(adres, { fetcher, resolveHost });
    expect(Buffer.from(bayt ?? []).subarray(0, 8)).toEqual(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
    const kalite = await kaynakGorseliniDogrula(adres, { fetcher, resolveHost });
    expect(kalite.tamam).toBe(true);
    expect(kalite.genislik).toBe(1200);
    const url = new URL(adres);
    const hash = new URLSearchParams(url.hash.slice(1));
    hash.set("vixrex-sha256", "0".repeat(64));
    url.hash = hash.toString();
    expect(await pdfKatalogGorseliniOku(url.toString(), { fetcher, resolveHost })).toBeNull();
  });

  it("ozel IP PDF kaynagini indirmez", async () => {
    let cagrildi = false;
    const hash = new URLSearchParams({ "vixrex-page": "1", "vixrex-image": "0", "vixrex-sha256": "0".repeat(64) });
    expect(await pdfKatalogGorseliniOku(`${pdfKaynak}#${hash}`, {
      resolveHost: async () => ["127.0.0.1"], fetcher: async () => {
        cagrildi = true; return new Response(Buffer.from(gercekPdf()));
      },
    })).toBeNull();
    expect(cagrildi).toBe(false);
  });

  it("boyut basligi olmadan siniri asan PDF akisinin kalanini okumaz", async () => {
    let iptal = false;
    let parca = 0;
    const fetcher = async () => new Response(new ReadableStream<Uint8Array>({
      pull(controller) { parca++; controller.enqueue(new Uint8Array(1024 * 1024)); },
      cancel() { iptal = true; },
    }), { headers: { "content-type": "application/pdf" } });
    expect(await hamGet(pdfKaynak, fetcher, resolveHost)).toBeNull();
    expect(iptal).toBe(true);
    expect(parca).toBeLessThanOrEqual(23);
  });
});
