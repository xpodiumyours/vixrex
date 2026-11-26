import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { supabase } from "@/lib/supabase";

// Onay kutusunun (PublishBar) linklediği yasal belge sayfası. `legal_documents`
// tablosundaki AKTİF sürümü okur — bu, accept_store_legal_consent RPC'sinin
// damgaladığı ve trg_validate_store_legal_acceptance'ın doğruladığı BİREBİR
// AYNI metindir (sürüm+hash). /privacy sayfası (statik, genel KVKK metni) ile
// KARIŞTIRILMASIN — bu sayfa yayınlama onayına özel, dinamik içeriktir; aynı
// mantık Flutter tarafında lib/screens/legal_screen.dart'ta da var, ikisi de
// aynı tabloyu okur.

const GECERLI_TURLER = ["privacy", "terms", "consent", "data-deletion"] as const;
type GecerliTur = (typeof GECERLI_TURLER)[number];

const BASLIK: Record<GecerliTur, string> = {
  privacy: "Aydınlatma Metni",
  terms: "Kullanım Şartları",
  consent: "Açık Rıza Beyanı",
  "data-deletion": "Hesap ve Veri Silme",
};

interface LegalSection {
  title?: string;
  body?: string;
}

interface Params {
  params: Promise<{ type: string }>;
}

const YEDEK_VERI_SILME_BELGESI = {
  title: BASLIK["data-deletion"],
  subtitle: "Hesabınızı ve verilerinizi nasıl silebileceğiniz.",
  version: "data-deletion-2026-08-28",
  sections: [
    {
      title: "Uygulama İçinden Silme",
      body: "Hesap ve Veri Yönetimi ekranından vitrininizi yayından kaldırabilir, vitrininizi kalıcı olarak silebilir veya hesabınızı tüm verileriyle birlikte silebilirsiniz. Kalıcı silme işlemleri geri alınamaz ve onay yazmanızı gerektirir.",
    },
    {
      title: "Silinen Veriler",
      body: "Hesap silindiğinde; giriş hesabınız, vitriniz, ürünleriniz, blog yazılarınız, randevu kayıtlarınız, galeri görselleriniz ve bağlantılı kayıtlarınız silinir. Vergi ve ticaret mevzuatı gereği saklanması zorunlu olan faturalandırma ve muhasebe kayıtları, ilgili yasal süreler boyunca saklanmaya devam eder.",
    },
    {
      title: "E-posta ile Talep",
      body: "Uygulamaya erişemiyorsanız destek@vixrex.com adresine talebinizi iletebilirsiniz. Kimliğinizin doğrulanmasının ardından talep en geç 30 gün içinde sonuçlandırılır.",
    },
  ] satisfies LegalSection[],
};

const YEDEK_KULLANIM_SARTLARI_BELGESI = {
  title: BASLIK.terms,
  subtitle: "Vixrex platformunu kullanarak bu şartları kabul etmiş olursunuz.",
  version: "terms-2026-08-28",
  sections: [
    {
      title: "Taraflar ve Hizmet",
      body: "Vixrex, Esenevler Mah. Lokman Hekim Cad. No:18 İç Kapı No:10 Ümraniye/İstanbul adresinde faaliyet gösteren Aksakal Ticaret (Furkan Aksakal, Ümraniye Vergi Dairesi, Vergi No: 0340472476) tarafından işletilen; kullanıcıların kendi işletme, ürün, hizmet ve iletişim bilgilerini dijital vitrin olarak yayınlayabildiği bir yazılım hizmetidir. Vixrex bir pazaryeri değildir; satış, tahsilat, kargo ve iade süreçlerine taraf olmaz. Müşteriyle kurulan her ticari ilişki işletme sahibi ile müşteri arasındadır.",
    },
    {
      title: "Hesap ve Kullanım",
      body: "Hesap açan kullanıcı, verdiği bilgilerin doğru ve güncel olduğunu kabul eder. Hesap güvenliğinden ve hesabı üzerinden yapılan işlemlerden kullanıcı sorumludur. Bir hesap ile bir vitrin açılabilir.",
    },
    {
      title: "İçerik Sorumluluğu",
      body: "Vitrine eklenen işletme bilgileri, fiyatlar, ürün ve hizmet açıklamaları, görseller, bağlantılar ve tüm içerikten yalnızca kullanıcı sorumludur. Kullanıcı, yüklediği içerik üzerinde gerekli haklara sahip olduğunu; içeriğin üçüncü kişilerin fikri mülkiyet, kişilik veya ticari haklarını ihlal etmediğini beyan eder. Yanıltıcı fiyat, taklit ürün, yasa dışı mal ve hizmet tanıtımı yasaktır. Vixrex içeriği önceden denetlemekle yükümlü değildir; ihlal bildirimi üzerine içeriği kaldırma hakkını saklı tutar.",
    },
    {
      title: "Ücretlendirme ve Fiyat Değişikliği",
      body: "Hizmetin ücretli paketleri, yayımlanan güncel fiyat listesi üzerinden sunulur. Vixrex, hizmet bedellerinde değişiklik yapma hakkını saklı tutar. Fiyat değişiklikleri, yürürlüğe girmeden en az 30 gün önce kullanıcıya e-posta veya uygulama içi bildirim ile duyurulur. Bildirimi takiben abonelik dönemini sürdüren kullanıcı yeni fiyatı kabul etmiş sayılır. Yeni fiyatı kabul etmeyen kullanıcı, bildirim tarihinden itibaren ücretsiz ve cezai şart ödemeksizin aboneliğini feshedebilir. Devam eden ödenmiş dönem için fiyat değişikliği uygulanmaz.",
    },
    {
      title: "Abonelik Süresi ve Fesih",
      body: "Abonelikler belirsiz sürelidir. Kullanıcı, aboneliğini herhangi bir gerekçe göstermeden, cezai şart ödemeksizin dilediği zaman feshedebilir; fesih, hesap ayarlarından ya da destek@vixrex.com adresine bildirim ile yapılır. Fesih, içinde bulunulan ödenmiş dönemin sonunda yürürlüğe girer ve o döneme ait ücret iade edilmez. Ücretsiz deneme vitrinleri, hesaba bağlanmamışsa 30 saat sonra otomatik silinir.",
    },
    {
      title: "Hizmetin Askıya Alınması ve Sona Erdirilmesi",
      body: "Vixrex; bu şartların ihlali, yasa dışı veya yanıltıcı içerik, ödeme yükümlülüğünün yerine getirilmemesi, sistemin güvenliğini tehdit eden kullanım veya üçüncü kişilerin haklarını ihlal eden davranış hâllerinde hesabı askıya alma veya sona erdirme hakkına sahiptir. Ağır ihlal ve hukuka aykırılık hâlleri dışında, askıya alma öncesinde kullanıcıya durumu düzeltmesi için makul süre tanınır.",
    },
    {
      title: "Hizmet Sürekliliği ve Değişiklikler",
      body: "Vixrex, hizmetin kesintisiz ve hatasız sunulacağını taahhüt etmez. Bakım, güncelleme, altyapı sağlayıcı kaynaklı arıza veya mücbir sebep hâllerinde geçici kesintiler yaşanabilir. Vixrex, hizmetin kapsamında ve özelliklerinde değişiklik yapma hakkını saklı tutar; kullanıcı aleyhine esaslı değişiklikler önceden duyurulur.",
    },
    {
      title: "Sorumluluğun Sınırı",
      body: "Vixrex, kullanıcının vitrininde yer verdiği bilgilerden, müşterileriyle kurduğu ticari ilişkiden, üçüncü kişilerin eylemlerinden ve dolaylı zararlardan (kâr kaybı, iş kaybı, veri kaybı, itibar zararı) sorumlu değildir. Vixrex'in her hâlükârda sorumluluğu, zararın doğduğu tarihten önceki son 12 ayda kullanıcının ödediği toplam hizmet bedeliyle sınırlıdır. Bu sınırlama, kanunen sınırlandırılamayan sorumluluk hâlleri bakımından uygulanmaz.",
    },
    {
      title: "Fikri Mülkiyet",
      body: "Vixrex adı, markası, arayüzü, yazılımı ve tasarımı üzerindeki haklar Aksakal Ticaret'e aittir. Kullanıcı, hizmeti kullanma hakkı dışında herhangi bir hak elde etmez. Kullanıcının yüklediği içerikler kendisine aittir; kullanıcı, hizmetin sunulabilmesi için bu içeriklerin barındırılması ve görüntülenmesi amacıyla Vixrex'e sınırlı ve ücretsiz kullanım izni verir.",
    },
    {
      title: "Şartlardaki Değişiklikler",
      body: "Bu şartlar güncellenebilir. Esaslı değişiklikler yürürlüğe girmeden önce kullanıcıya bildirilir. Bildirimden sonra hizmeti kullanmaya devam eden kullanıcı, güncellenmiş şartları kabul etmiş sayılır.",
    },
    {
      title: "Uyuşmazlık ve Uygulanacak Hukuk",
      body: "Bu şartlara Türkiye Cumhuriyeti hukuku uygulanır. Uyuşmazlıklarda İstanbul Anadolu Mahkemeleri ve İcra Daireleri yetkilidir. Tüketici sıfatını haiz kullanıcılar bakımından, ilgili parasal sınırlar dâhilinde Tüketici Hakem Heyetleri ve tüketicinin yerleşim yerindeki tüketici mahkemeleri yetkilidir.",
    },
    {
      title: "İletişim",
      body: "Şartlar, içerik şikayeti, fesih ve hesap talepleri için destek@vixrex.com adresine veya 0542 180 25 73 numarasına ulaşabilirsiniz.",
    },
  ] satisfies LegalSection[],
};

function gecerliTurMu(deger: string): deger is GecerliTur {
  return (GECERLI_TURLER as readonly string[]).includes(deger);
}

async function belgeyiGetir(tur: GecerliTur) {
  try {
    const sorgu = supabase
      .from("legal_documents")
      .select("title, subtitle, sections, version");
    const filtreliSorgu =
      tur === "data-deletion"
        ? sorgu.in("document_type", ["data-deletion", "dataDeletion"])
        : sorgu.eq("document_type", tur);
    const { data } = await filtreliSorgu
      .eq("is_active", true)
      .limit(1)
      .maybeSingle();
    return data;
  } catch {
    return null;
  }
}

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const { type } = await params;
  if (!gecerliTurMu(type)) return { title: "Yasal Belge | Vixrex" };
  return { title: `${BASLIK[type]} | Vixrex` };
}

export default async function LegalTypePage({ params }: Params) {
  const { type } = await params;
  if (!gecerliTurMu(type)) notFound();

  const belge = await belgeyiGetir(type);
  const yedekBelge =
    type === "data-deletion"
      ? YEDEK_VERI_SILME_BELGESI
      : type === "terms"
        ? YEDEK_KULLANIM_SARTLARI_BELGESI
        : null;
  if (!belge && !yedekBelge) notFound();

  const gosterilecekBelge = (belge ?? yedekBelge) as {
    title?: string;
    subtitle?: string;
    version?: string;
    sections?: LegalSection[];
  };
  const sections = Array.isArray(gosterilecekBelge.sections)
    ? (gosterilecekBelge.sections as LegalSection[])
    : [];

  return (
    <main
      style={{
        maxWidth: 720,
        margin: "0 auto",
        padding: "40px 20px",
        color: "#EDEDED",
      }}
    >
      <h1>{gosterilecekBelge.title || BASLIK[type]}</h1>
      {gosterilecekBelge.subtitle ? <p>{gosterilecekBelge.subtitle}</p> : null}

      {sections.map((section, index) => (
        <section key={index}>
          {section.title ? <h2>{section.title}</h2> : null}
          {section.body ? <p style={{ whiteSpace: "pre-wrap" }}>{section.body}</p> : null}
        </section>
      ))}

      <p style={{ opacity: 0.6, fontSize: 13, marginTop: 32 }}>
        Sürüm: {gosterilecekBelge.version}
      </p>
    </main>
  );
}
