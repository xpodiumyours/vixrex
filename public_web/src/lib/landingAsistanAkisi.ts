import { FIELD_BY_KEY } from "@/lib/vitrinFieldSchema";
import {
  vixRexAsistanAkisi,
  vixRexMesajlari,
  type VixRexAsistanAkisAdimi,
} from "@/lib/vixrexMesajlari";

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
  assistant_handoff?: {
    version: 1;
    completed_steps: ["name", "category", "whatsapp", "location", "legal", "publish"];
    next_step: null;
    messages: { role: "assistant" | "user"; text: string }[];
  };
}

export function asistanHandoffOlustur(
  cevaplar: AsistanCevaplari,
): NonNullable<AsistanCevaplari["assistant_handoff"]> {
  const messages: { role: "assistant" | "user"; text: string }[] = [
    {
      role: "assistant",
      text: `${ASISTAN_KARSILAMA.baslik}\n${ASISTAN_KARSILAMA.aciklama}`,
    },
  ];
  for (const adim of ASISTAN_ADIMLARI) {
    const cevap = adim.alan === "location"
      ? [cevaplar.district_name, cevaplar.province_name, cevaplar.address]
          .filter(Boolean)
          .join(" — ")
      : adim.cevapAnahtari
        ? String(cevaplar[adim.cevapAnahtari] ?? "")
        : "";
    messages.push(
      { role: "assistant", text: `${adim.baslik}\n${adim.aciklama}` },
      { role: "user", text: cevap },
    );
  }
  return {
    version: 1,
    completed_steps: ["name", "category", "whatsapp", "location", "legal", "publish"],
    next_step: null,
    messages,
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
