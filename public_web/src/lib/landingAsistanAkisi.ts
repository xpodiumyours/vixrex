import { FIELD_BY_KEY } from "@/lib/vitrinFieldSchema";
import {
  vixRexAsistanAkisi,
  vixRexMesajlari,
  type VixRexAsistanAkisAdimi,
} from "@/lib/vixrexMesajlari";
import type {
  AssistantHandoffStep,
  AssistantHandoffV1,
} from "@/lib/assistantHandoff";

/**
 * Ana sayfadaki Vixrex Asistan'ın konuşma akışı.
 *
 * TEK KAYNAK KURALI: buradaki hiçbir kullanıcı metni elle yazılmaz.
 * Hepsi `shared/vixrex_mesajlar.json` katalogundan gelir — Flutter da aynı
 * dosyayı okuyor (`lib/config/vixrex_mesajlar.g.dart`). Böylece asistan
 * iki yüzeyde de aynı sözleri kullanır ve ayrışamaz.
 *
 * NEDEN AYRI DOSYA: akışın kendisi (hangi adım, hangi sırayla, hangi
 * doğrulama) bir veri yapısı. Bileşenin içine gömülürse ikinci bir akış
 * tanımı doğar ve "tek beyin" iddiası biter.
 *
 * KAPSAM: landing sohbeti DEMO kipindedir — hiçbir şey veritabanına
 * yazılmaz. Yasal onay ve yayınlama adımları (setup_legal_*,
 * setup_publish_*) burada YOK; ikisi de hesap gerektiriyor ve kayıt
 * sonrasına ait. Toplanan cevaplar tarayıcıda tutulup kayıt akışına
 * taşınır.
 */

export type AsistanAdimi = {
  alan: VixRexAsistanAkisAdimi["id"];
  kolonlar: string[];
  cevapAnahtari: keyof AsistanCevaplari | null;
  girdi: VixRexAsistanAkisAdimi["girdi"];
  baslik: string;
  aciklama: string;
  dugme: string;
  yerTutucu: string;
  /** Boş bırakılabilir mi — vitrin kurmak için yalnız ad zorunlu. */
  zorunlu: boolean;
  secenekler: readonly string[];
};

function metin(anahtar: string): string {
  const deger = vixRexMesajlari[anahtar];
  if (!deger) {
    // Sessizce boş string döndürmek, katalogdan silinen bir anahtarı
    // ekranda görünmez hâle getirirdi. Gürültülü başarısızlık daha iyi.
    throw new Error(
      `Vixrex mesaj katalogunda '${anahtar}' yok — shared/vixrex_mesajlar.json`
    );
  }
  return deger;
}

export const ASISTAN_KARSILAMA = {
  baslik: metin("welcome_baslik"),
  aciklama: metin("welcome_aciklama"),
  dugme: metin("welcome_buton"),
};

const CEVAP_ANAHTARLARI: Readonly<Record<string, keyof AsistanCevaplari>> = {
  isletmeAdi: "name",
  kategori: "kategori",
  whatsapp: "whatsapp",
};

export const ASISTAN_ADIMLARI: AsistanAdimi[] = vixRexAsistanAkisi
  .filter((adim) => ["name", "category", "whatsapp", "location", "legal", "publish"].includes(adim.id))
  .map((adim) => {
    const alanlar = adim.alanlar.map((anahtar) => FIELD_BY_KEY.get(anahtar));
    if (alanlar.some((alan) => !alan)) {
      throw new Error(`Vixrex asistan akışında tanımsız alan var: ${adim.alanlar.join(", ")}`);
    }
    const ilkAlan = alanlar[0];
    return {
      alan: adim.id,
      kolonlar: alanlar.map((alan) => alan!.kolon),
      cevapAnahtari: ilkAlan ? (CEVAP_ANAHTARLARI[ilkAlan.anahtar] ?? null) : null,
      girdi: adim.girdi,
      baslik: metin(`${adim.mesaj}_baslik`),
      aciklama: metin(`${adim.mesaj}_aciklama`),
      dugme: metin(`${adim.mesaj}_buton`),
      yerTutucu: adim.yerTutucu ?? "",
      zorunlu: alanlar.some((alan) => alan!.zorunlu === true),
      secenekler: ilkAlan?.secenekler ?? [],
    };
  });

export const ASISTAN_BITIS = {
  baslik: metin("landing_finish_baslik"),
  aciklama: metin("landing_finish_aciklama"),
  dugme: metin("landing_finish_buton"),
};

/** Sohbette toplanan cevaplar. Veritabanına değil, tarayıcıya yazılır. */
export interface AsistanCevaplari {
  name?: string;
  kategori?: string;
  whatsapp?: string;
  address?: string;
  province_name?: string;
  district_name?: string;
  latitude?: number;
  longitude?: number;
  location_accuracy_meters?: number;
  location_source?: "browser_gps" | "manual";
  legal_consent?: boolean;
  aydinlatma_onay?: boolean;
  sartlar_onay?: boolean;
  acik_riza_onay?: boolean;
  assistant_handoff?: AssistantHandoffV1;
}

/**
 * Handoff adım adı eşlemesi.
 *
 * `shared/vixrex_mesajlar.json` akışı `publish` der; DB'nin
 * `sanitize_assistant_handoff` izin listesi ise `publishing` bekler
 * (20260811180000_assistant_handoff_core.sql). İsim uyuşmazlığı canlıda
 * "asistan konuşması aktarılamadı" hatası üretti; yayın adımı sessizce
 * reddediliyordu.
 */
const HANDOFF_ADIMLARI: Record<
  AsistanAdimi["alan"],
  Exclude<AssistantHandoffStep, "done">
> = {
  name: "name",
  category: "category",
  whatsapp: "whatsapp",
  location: "location",
  legal: "legal",
  publish: "publishing",
  share: "publishing",
};

/** DB, boş kullanıcı metnini de reddeder (INVALID_ASSISTANT_HANDOFF_MESSAGE). */
export function handoffMesajMetni(
  adim: AsistanAdimi,
  cevaplar: AsistanCevaplari,
): string {
  const ham = adim.alan === "location"
    ? [cevaplar.district_name, cevaplar.province_name, cevaplar.address]
        .filter(Boolean)
        .join(" — ")
    : adim.cevapAnahtari
      ? String(cevaplar[adim.cevapAnahtari] ?? "")
      : "";

  if (ham.trim()) return ham;

  if (adim.alan === "legal") {
    return cevaplar.legal_consent === true ? "Onaylandı" : "Onaylanmadı";
  }
  return adim.dugme;
}

export interface AsistanHandoffDurumu {
  /** Vitrin gerçekten oluşturulup yayınlandıysa yayın adımı "tamamlandı" sayılır. */
  yayinlandi?: boolean;
}

function tamamlananAdimlar(
  cevaplar: AsistanCevaplari,
  durum: AsistanHandoffDurumu,
): Array<Exclude<AssistantHandoffStep, "done">> {
  const tamamlanan: Array<Exclude<AssistantHandoffStep, "done">> = [];
  if (cevaplar.name?.trim()) tamamlanan.push("name");
  if (cevaplar.kategori?.trim()) tamamlanan.push("category");
  if (cevaplar.whatsapp?.trim()) tamamlanan.push("whatsapp");
  const konumVar = Boolean(
    cevaplar.province_name?.trim() ||
      cevaplar.district_name?.trim() ||
      cevaplar.address?.trim(),
  );
  if (konumVar) tamamlanan.push("location");
  if (cevaplar.legal_consent === true) tamamlanan.push("legal");
  if (durum.yayinlandi) tamamlanan.push("publishing");
  return tamamlanan;
}

/**
 * Konuşma aktarımı yalnız GERÇEKTEN cevaplanmış adımları taşır. Yayın
 * adımı ancak yayınlama çağrısı başarıyla tamamlandığında "tamamlandı"
 * olur; aksi hâlde sahip paneli "onaylamadın" gibi yanlış bir geçmişle
 * açılıyordu (2026-11-14 bulgusu).
 */
export function asistanHandoffOlustur(
  cevaplar: AsistanCevaplari,
  durum: AsistanHandoffDurumu = {},
): AssistantHandoffV1 {
  const tamamlanan = tamamlananAdimlar(cevaplar, durum);
  const messages: { role: "assistant" | "user"; text: string }[] = [
    {
      role: "assistant",
      text: `${ASISTAN_KARSILAMA.baslik}\n${ASISTAN_KARSILAMA.aciklama}`,
    },
  ];
  for (const adim of ASISTAN_ADIMLARI) {
    const handoffAdim = HANDOFF_ADIMLARI[adim.alan];
    if (!tamamlanan.includes(handoffAdim)) continue;
    messages.push(
      { role: "assistant", text: `${adim.baslik}\n${adim.aciklama}` },
      { role: "user", text: handoffMesajMetni(adim, cevaplar) },
    );
  }
  const siradaki = ASISTAN_ADIMLARI.find(
    (adim) => !tamamlanan.includes(HANDOFF_ADIMLARI[adim.alan]),
  );
  return {
    version: 1,
    completed_steps: tamamlanan,
    next_step: siradaki ? HANDOFF_ADIMLARI[siradaki.alan] : "done",
    messages,
  };
}

export interface AsistanYasalOnaylar {
  aydinlatma: boolean;
  sartlar: boolean;
  acikRiza: boolean;
}

/**
 * Yayın gövdesini ve kayıt sonrası taşınacak taslağı TEK yerden üretir.
 * Handoff burada, yasal onay verildikten SONRA yeniden üretilir; konum
 * adımında donmuş eski kopya artık gönderilmez.
 */
export function yayinCevaplariHazirla(
  cevaplar: AsistanCevaplari,
  onaylar: AsistanYasalOnaylar,
  durum: AsistanHandoffDurumu = {},
): AsistanCevaplari {
  const birlesik: AsistanCevaplari = {
    ...cevaplar,
    legal_consent: true,
    aydinlatma_onay: onaylar.aydinlatma,
    sartlar_onay: onaylar.sartlar,
    acik_riza_onay: onaylar.acikRiza,
  };
  return {
    ...birlesik,
    assistant_handoff: asistanHandoffOlustur(birlesik, durum),
  };
}

export const ASISTAN_TASLAK_ANAHTARI = "vixrex_asistan_taslak";

export function taslagiKaydet(cevaplar: AsistanCevaplari): void {
  if (typeof window === "undefined") return;
  try {
    window.sessionStorage.setItem(
      ASISTAN_TASLAK_ANAHTARI,
      JSON.stringify(cevaplar)
    );
  } catch {
    // Gizli sekmede depolama kapalı olabilir; sohbet yine çalışsın.
  }
}

export function taslagiOku(): AsistanCevaplari {
  if (typeof window === "undefined") return {};
  try {
    const ham = window.sessionStorage.getItem(ASISTAN_TASLAK_ANAHTARI);
    return ham ? (JSON.parse(ham) as AsistanCevaplari) : {};
  } catch {
    return {};
  }
}

export function taslagiTemizle(): void {
  if (typeof window === "undefined") return;
  try {
    window.sessionStorage.removeItem(ASISTAN_TASLAK_ANAHTARI);
  } catch {
    // yoksay
  }
}
