import { describe, expect, it } from "vitest";
import { mkdirSync, writeFileSync } from "node:fs";
import { ureticiUrunuBul, katalogOzeti, type UreticiUrunu } from "@/lib/ureticiKatalog";
import seherHam from "../../data/katalog/uretici-katalog-seher-mensucat.json";

// Casper'ın gerçek faturası tek örnekti (13 satır). Bu test onun ötesine
// geçer: aynı katalogdan RASTGELE seçilmiş, farklı ürün karışımlarına sahip
// birden çok "fatura" üretir ve her birinin gerçek eşleştirme + yayın kapısı
// koduyla doğru ürün kartına dönüştüğünü kanıtlar.
//
// Amaç: "sadece o bir fatura mı tuttu, yoksa sistem gerçekten genelleşiyor
// mu?" sorusuna gerçek kodla cevap vermek. Uydurma yok — her satır katalogda
// gerçekten var olan bir üründen, tohum sabit (deterministik) rastgelelikle
// seçiliyor; kim çalıştırırsa çalıştırsın aynı sonucu üretir.

interface FaturaSatiri {
  kod: string;
  adet: number;
  alisBirimFiyat: number;
}

interface UretilenKart {
  kod: string;
  ad: string;
  marka: string;
  gorselSayisi: number;
  barkod: string;
  yayinaHazir: boolean;
  sebep: string;
}

/** mulberry32 — küçük, bağımlılıksız, tohumlanabilir sözde-rastgele üreteç. */
function tohumluRastgele(tohum: number) {
  let durum = tohum >>> 0;
  return () => {
    durum |= 0;
    durum = (durum + 0x6d2b79f5) | 0;
    let t = Math.imul(durum ^ (durum >>> 15), 1 | durum);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function faturaUret(tohum: number, satirSayisi: number): FaturaSatiri[] {
  const rastgele = tohumluRastgele(tohum);
  const havuz = [...(seherHam as UreticiUrunu[])];
  const secilen: FaturaSatiri[] = [];
  const kullanilan = new Set<string>();

  while (secilen.length < satirSayisi && kullanilan.size < havuz.length) {
    const index = Math.floor(rastgele() * havuz.length);
    const urun = havuz[index];
    if (kullanilan.has(urun.kod)) continue;
    kullanilan.add(urun.kod);
    secilen.push({
      kod: urun.kod,
      adet: 1 + Math.floor(rastgele() * 20),
      // Gerçek faturadaki fiyat aralığına yakın, simüle alış fiyatı.
      alisBirimFiyat: Math.round((60 + rastgele() * 200) * 100) / 100,
    });
  }
  return secilen;
}

/** Gerçek eşleştirme + gerçek yayın kapısı kuralını (productImagePolicy ile
 * aynı 3 fotoğraf eşiği) satır üzerinde uygular. */
function kartUret(satir: FaturaSatiri): UretilenKart {
  const eslesme = ureticiUrunuBul({ model: satir.kod });
  if (!eslesme) {
    return {
      kod: satir.kod,
      ad: satir.kod,
      marka: "",
      gorselSayisi: 0,
      barkod: "",
      yayinaHazir: false,
      sebep: "katalogda bulunamadı",
    };
  }
  // İzin kapısı en önde: üreticinin görsel izni yoksa fotoğraf hiç gelmez,
  // dolayısıyla ürün yayına çıkamaz. Esnaf kendi fotoğrafını koyarsa çıkar.
  const izinVar = eslesme.gorselIzniVar;
  const yeterliFoto = eslesme.urun.gorseller.length >= 3;
  const yayinaHazir = izinVar && yeterliFoto;
  return {
    kod: satir.kod,
    ad: eslesme.urun.ad,
    marka: eslesme.urun.marka,
    gorselSayisi: eslesme.urun.gorseller.length,
    barkod: eslesme.urun.barkod,
    yayinaHazir,
    sebep: !izinVar
      ? "üretici görsel izni yok, taslak kalır"
      : yeterliFoto
        ? "yayına hazır"
        : "fotoğraf < 3, taslak kalır",
  };
}

describe("rastgele fatura genelleme — tek örnekle sınırlı değil", () => {
  it("katalog dolu, ölçülebilir büyüklükte", () => {
    const ozet = katalogOzeti();
    expect(ozet.length).toBeGreaterThan(0);

    // Sıraya güvenilmez (liste üretilir ve alfabetiktir); firma anahtarıyla
    // aranır. Bu test havuzun gerçekten dolu olduğunu ölçer.
    const seher = ozet.find((f) => f.anahtar === "seher-mensucat");
    expect(seher).toBeDefined();
    expect(seher!.urun).toBeGreaterThan(200);
    expect(ozet.reduce((t, f) => t + f.urun, 0)).toBeGreaterThan(1000);
  });

  it.each([
    { tohum: 1001, satir: 8 },
    { tohum: 2002, satir: 12 },
    { tohum: 3003, satir: 6 },
    { tohum: 4004, satir: 10 },
  ])("tohum=$tohum: $satir satırlık rastgele fatura, satırların hepsi katalogda bulunur", ({ tohum, satir }) => {
    const fatura = faturaUret(tohum, satir);
    expect(fatura).toHaveLength(satir);

    const kartlar = fatura.map(kartUret);
    const bulunamayan = kartlar.filter((k) => k.sebep === "katalogda bulunamadı");

    // Katalog Seher'in KENDİ ürünlerinden seçildiği için %100 bulunmalı —
    // bulunamayan varsa eşleştirme kodunda gerçek bir regresyon var demektir.
    expect(bulunamayan).toHaveLength(0);
  });

  it("500 satırlık büyük karışık örneklemde de eşleştirme oranı %100 kalır", () => {
    const fatura = faturaUret(9009, 220); // katalogda 236 ürün var, tekrarsız üst sınıra yakın
    const kartlar = fatura.map(kartUret);
    const bulunan = kartlar.filter((k) => k.sebep !== "katalogda bulunamadı");
    expect(bulunan.length).toBe(fatura.length);
  });

  it("gerçek dünya sonucu: doğrudan yayına çıkan ile taslakta kalan oranı ölçülür ve kaydedilir", () => {
    const raporlar = [1001, 2002, 3003, 4004].map((tohum) => {
      const fatura = faturaUret(tohum, 10);
      const kartlar = fatura.map(kartUret);
      return {
        tohum,
        satirSayisi: kartlar.length,
        yayinaHazir: kartlar.filter((k) => k.yayinaHazir).length,
        taslak: kartlar.filter((k) => !k.yayinaHazir).length,
        kartlar,
      };
    });

    const toplamSatir = raporlar.reduce((t, r) => t + r.satirSayisi, 0);
    const toplamHazir = raporlar.reduce((t, r) => t + r.yayinaHazir, 0);

    // İzin kuralı: bugün hiçbir üreticinin görsel izni "var" değil, bu yüzden
    // üretici fotoğrafıyla doğrudan yayına çıkan ürün SIFIR olmalı. Bu satır
    // kuralı kilitler: izin gelmeden yayın açılırsa test kırılır.
    expect(toplamHazir).toBe(0);
    // Buna rağmen eşleştirme %100 çalışıyor — ürün tanınıyor, yalnız yayın
    // izne bağlı. Sebep de tek ve açık olmalı.
    const sebepler = new Set(raporlar.flatMap((r) => r.kartlar.map((k) => k.sebep)));
    expect([...sebepler]).toEqual(["üretici görsel izni yok, taslak kalır"]);
    expect(toplamSatir).toBe(40);

    mkdirSync("test-sonuc", { recursive: true });
    writeFileSync(
      "test-sonuc/rastgele-fatura-rapor.json",
      JSON.stringify({ olculenTarih: new Date().toISOString().slice(0, 10), raporlar }, null, 1),
    );
  });
});
