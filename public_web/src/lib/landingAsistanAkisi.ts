import { vixRexMesajlari } from "@/lib/vixrexMesajlari";

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
  /** Toplanan cevabın anahtarı; `create-store` gövdesiyle aynı adlandırma. */
  alan: "name" | "kategori" | "whatsapp" | "address";
  baslik: string;
  aciklama: string;
  dugme: string;
  yerTutucu: string;
  /** Boş bırakılabilir mi — vitrin kurmak için yalnız ad zorunlu. */
  zorunlu: boolean;
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

export const ASISTAN_ADIMLARI: AsistanAdimi[] = [
  {
    alan: "name",
    baslik: metin("setup_name_baslik"),
    aciklama: metin("setup_name_aciklama"),
    dugme: metin("setup_name_buton"),
    yerTutucu: "Ör. Aymira Giyim",
    zorunlu: true,
  },
  {
    alan: "kategori",
    baslik: metin("setup_category_baslik"),
    aciklama: metin("setup_category_aciklama"),
    dugme: metin("setup_category_buton"),
    yerTutucu: "Ör. Butik & Giyim",
    zorunlu: false,
  },
  {
    alan: "whatsapp",
    baslik: metin("setup_whatsapp_baslik"),
    aciklama: metin("setup_whatsapp_aciklama"),
    dugme: metin("setup_whatsapp_buton"),
    yerTutucu: "05xx xxx xx xx",
    zorunlu: false,
  },
  {
    alan: "address",
    baslik: metin("setup_address_baslik"),
    aciklama: metin("setup_address_aciklama"),
    dugme: metin("setup_address_buton"),
    yerTutucu: "Mahalle, ilçe, il",
    zorunlu: false,
  },
];

export const ASISTAN_BITIS = {
  baslik: metin("landing_finish_baslik"),
  aciklama: metin("landing_finish_aciklama"),
  dugme: metin("landing_finish_buton"),
};

/** Sohbette toplanan cevaplar. Veritabanına değil, tarayıcıya yazılır. */
export type AsistanCevaplari = Partial<Record<AsistanAdimi["alan"], string>>;

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
