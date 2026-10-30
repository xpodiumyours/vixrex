import type { SupabaseClient } from "@supabase/supabase-js";
import { faturaIstekGovdesi, faturaYanitiniOku, type GoruSonucu } from "@/lib/faturaGoru";
import { faturaSatiriniAktar } from "@/lib/faturaPresetAktarimi";
import { islemKaydet } from "@/lib/faturaIslemKaydi";
import { islemiYukle } from "@/lib/faturaIslemOku";
import { faturaTaslakYanitiniHazirla } from "@/lib/faturaOtomatikTaslakKaydi";
import {
  kartPresetIstekGovdesi,
  kartPresetYanitiniOku,
  URUN_KART_PRESET,
} from "@/lib/faturaKartPreset";
import { gorselsizSatirlariTamamla } from "@/lib/faturaGorsel";
import { adayGorselleriniSec } from "@/lib/faturaGorselSecimi";
import { faturaBaslangicZamani, faturaOzetSatiri, faturaOzetiniKaydet, gecenSaniye } from "@/lib/faturaOzeti";

export const OKUMA_PRESET = "@preset/vixrex-qwen-fatura-okuma-suzme";
export const OTOMATIK_FATURA_PRESET = URUN_KART_PRESET;

export function bekleyenFaturaYaniti(islemKimligi: string, asama: "okunuyor" | "kartlaniyor" = "okunuyor") {
  return {
    tamam: false,
    hazirlaniyor: true,
    islemKimligi,
    asama,
    mesaj: "Fatura okunuyor ve ürün kartları hazırlanıyor. Aynı faturayı tekrar yüklemene gerek yok.",
  };
}

/** Sahiplik dosya API'sinde doğrulanır. Bu köprü araştırma veya ürün kararı vermez. */
export async function faturayiArkaPlanaGonder(
  admin: SupabaseClient,
  storeId: string,
  parmakIzi: string,
  goruntu: string | string[],
): Promise<string> {
  const anahtar = process.env.OPENROUTER_API_KEY;
  if (!anahtar) throw new Error("OKUYUCU_HAZIR_DEGIL");
  const body = { ...faturaIstekGovdesi(goruntu), model: OKUMA_PRESET };
  const { data, error } = await admin.rpc("enqueue_invoice_provider_job", {
    p_store_id: storeId,
    p_fingerprint: parmakIzi,
    p_body: body,
    p_api_key: anahtar,
  });
  if (error || data?.success !== true || typeof data.id !== "string") {
    // RPC hata nesnesinde istek parametreleri bulunabilir; anahtar/fotoğraf loglanmaz.
    throw new Error("OKUYUCU_ISLEYICI_HAZIR_DEGIL");
  }
  return data.id;
}

/** Provider'ın gerçek sonucu, aynı mağazaya ait private işten okunur. */
export async function arkaPlanFaturaSonucunuAl(
  admin: SupabaseClient,
  storeId: string,
  slug: string,
  islemKimligi: string,
): Promise<Record<string, unknown>> {
  const { data: sonuc, error } = await admin.rpc("get_invoice_provider_response", {
    p_store_id: storeId,
    p_job_id: islemKimligi,
  });
  if (error) throw new Error("OKUYUCU_ISLEYICI_HAZIR_DEGIL");
  if (!sonuc) throw new Error("FATURA_ISLEMI_BULUNAMADI");
  if (sonuc.state === "queued") return bekleyenFaturaYaniti(islemKimligi, sonuc.stage === "cards" ? "kartlaniyor" : "okunuyor");
  if (sonuc.state === "failed") throw new Error(typeof sonuc.error === "string" && /^[A-Z_]{1,96}$/.test(sonuc.error) ? sonuc.error : "OKUYUCU_ISLEMI_TAMAMLANMADI");
  if (sonuc.state === "processed") {
    const kayit = await islemiYukle(admin, storeId, islemKimligi);
    if (!kayit?.satirlar.length) throw new Error("FATURA_KAYDI_EKSIK");
    return faturaTaslakYanitiniHazirla(admin, storeId, slug, kayit);
  }
  if (sonuc.state !== "received" || typeof sonuc.body !== "string" || typeof sonuc.fingerprint !== "string") {
    throw new Error("OKUYUCU_EKSIK_CEVAP");
  }
  try {
    const httpStatus = Number(sonuc.httpStatus);
    if (!Number.isInteger(httpStatus) || httpStatus < 200 || httpStatus > 599) throw new Error("OKUYUCU_CEVAP_VERMEDI");
    const cevap = new Response(sonuc.body, {
      status: httpStatus,
      headers: { "content-type": typeof sonuc.contentType === "string" ? sonuc.contentType : "application/json" },
    });
    // Fatura okuyucusu ile ürün kartı preset'i farklı JSON sözleşmeleri üretir.
    // İlk sonucu yalnızca bir kez okur, ikinciyi row_id ile eşleştirir.
    let okuma: GoruSonucu;
    let kartCevabi: unknown;
    let asamaKullanimlari: unknown;
    if (sonuc.stage === "reading") {
      okuma = await faturaYanitiniOku(cevap);
      if (!okuma.satirlar.length) throw new Error("FOTOGRAFTA_YAZI_YOK");
      const ikinci = await admin.rpc("advance_invoice_provider_job", {
        p_store_id: storeId,
        p_job_id: islemKimligi,
        p_read_result: okuma,
        p_body: kartPresetIstekGovdesi(okuma),
        p_api_key: process.env.OPENROUTER_API_KEY,
      });
      if (ikinci.error || ikinci.data?.success !== true) throw new Error("KART_ISLEYICI_HAZIR_DEGIL");
      return bekleyenFaturaYaniti(islemKimligi, "kartlaniyor");
    } else if (sonuc.stage === "cards") {
      const ilkOkuma = sonuc.readResult as GoruSonucu | null;
      if (!ilkOkuma || !Array.isArray(ilkOkuma.satirlar) || !ilkOkuma.satirlar.length) {
        throw new Error("OKUYUCU_EKSIK_CEVAP");
      }
      const kart = await kartPresetYanitiniOku(cevap, ilkOkuma);
      okuma = kart.sonuc;
      kartCevabi = kart.kartCevabi;
      asamaKullanimlari = {
        okuma: { gercekMaliyet: ilkOkuma.gercekMaliyet, girdiToken: ilkOkuma.girdiToken,
          ciktiToken: ilkOkuma.ciktiToken, akilToken: ilkOkuma.akilToken },
        kart: kart.kullanim,
      };
    } else {
      throw new Error("OKUYUCU_EKSIK_CEVAP");
    }
    const tamamlanmis = await gorselsizSatirlariTamamla({ satirlar: okuma.satirlar });
    const birlesikOkuma = { ...okuma, satirlar: await adayGorselleriniSec({ satirlar: tamamlanmis }) };
    const satirlar = birlesikOkuma.satirlar.map((s) => faturaSatiriniAktar(s, birlesikOkuma.tedarikci));
    const id = await islemKaydet({
      slug, parmakIzi: sonuc.fingerprint, providerJobId: islemKimligi,
      belgeAdedi: birlesikOkuma.belgeAdedi, belgeToplami: birlesikOkuma.belgeToplami,
      tedarikci: birlesikOkuma.tedarikci, tedarikciVergiNo: birlesikOkuma.tedarikciVergiNo,
      tedarikciAdres: birlesikOkuma.tedarikciAdres, tedarikciSite: birlesikOkuma.tedarikciSite,
      tedarikciIz: null, satirlar,
      belgeTuru: birlesikOkuma.belgeTuru, belgeNo: birlesikOkuma.belgeNo, belgeTarihi: birlesikOkuma.belgeTarihi,
      malBedeli: birlesikOkuma.malBedeli, kdvTutari: birlesikOkuma.kdvTutari,
      indirimTutari: birlesikOkuma.indirimTutari, odenecekToplam: birlesikOkuma.odenecekToplam,
      belgeUyarisi: (birlesikOkuma.uyarilar ?? []).join(" · "),
      aramaDurumu: {
        erisimHatasi: satirlar.some((s) => s.dogrulamaDurumu?.includes("Araştırılamadı")),
        sonrakiSatir: satirlar.length,
        presetCevabi: { belgeEkleri: birlesikOkuma.belgeEkleri, gruplar: birlesikOkuma.gruplar,
          uyarilar: birlesikOkuma.uyarilar, kartCevabi, asamaKullanimlari },
      },
    });
    if (id !== islemKimligi) throw new Error("FATURA_KAYDI_EKSIK");
    const kayit = await islemiYukle(admin, storeId, islemKimligi);
    if (!kayit?.satirlar.length) throw new Error("FATURA_KAYDI_EKSIK");
    return faturaTaslakYanitiniHazirla(admin, storeId, slug, kayit);
  } catch (err) {
    const kod = err instanceof Error && /^[A-Z_]{1,96}$/.test(err.message) ? err.message : "OKUYUCU_CEVAP_VERMEDI";
    await faturaOzetiniKaydet(admin, storeId, islemKimligi, faturaOzetSatiri({
      islemKimligi, satirSayisi: 0, kartSayisi: 0, gorselliSayisi: 0,
      sureSaniye: gecenSaniye(await faturaBaslangicZamani(admin, storeId, islemKimligi)), hataKodu: kod,
    }));
    // Geçici DB yazma/okuma hatasında alınmış cevabı harcamadan sonraki GET ile yeniden kaydet.
    if (!["FATURA_KAYDI_EKSIK", "KART_ISLEYICI_HAZIR_DEGIL"].includes(kod)) {
      await admin.rpc("fail_invoice_provider_job", { p_store_id: storeId, p_job_id: islemKimligi, p_error: kod });
    }
    throw new Error(kod);
  }
}

export function arkaPlanFaturaHatasi(kod: string): string {
  if (kod === "OKUYUCU_ISLEYICI_HAZIR_DEGIL") return "Otomatik fatura işleyicisi şu anda hazır değil. Ürün oluşturulmadı.";
  if (kod === "OKUYUCU_MODEL_BULUNAMADI") return "OpenRouter modeline şu anda erişilemiyor. Ürün kartları tamamlanmadı.";
  if (kod === "OKUYUCU_UCRETSIZ_KOTA_DOLDU") return "OpenRouter günlük ücretsiz model sınırına ulaştı. Ürün kartları tamamlanmadı.";
  if (kod === "OKUYUCU_BAKIYE_BITTI") return "OpenRouter fatura işlemini tamamlayamadı. Hesabın kullanım durumunu kontrol edin.";
  if (kod === "FOTOGRAFTA_YAZI_YOK") return "Fotoğraftan ürün satırı alınamadı. Ürün oluşturulmadı.";
  if (kod === "FATURA_KAYDI_EKSIK") return "Gerçek sonuç alındı ancak kaydı henüz tamamlanmadı. Aynı işlemden devam edebilirsin.";
  if (kod === "KART_ISLEYICI_HAZIR_DEGIL") return "Fatura okundu ancak ürün kartı aşaması başlatılamadı. Aynı işlemden devam et.";
  if (kod === "KART_SATIRLARI_ESLESMEDI") return "Kart yanıtındaki ürün kimlikleri faturayla eşleşmedi; yanlış karta bilgi yazılmadı.";
  if (kod === "KART_YANITI_COZULEMEDI") return "İkinci preset JSON yanıtı doğrulanamadı; ürün kartı kaydedilmedi.";
  return "OpenRouter ürün hazırlamayı tamamlayamadı. Eksik cevap ürün kartı olarak kaydedilmedi.";
}
