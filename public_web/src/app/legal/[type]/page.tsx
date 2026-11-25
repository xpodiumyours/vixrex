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

function gecerliTurMu(deger: string): deger is GecerliTur {
  return (GECERLI_TURLER as readonly string[]).includes(deger);
}

async function belgeyiGetir(tur: GecerliTur) {
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
  if (!belge && type !== "data-deletion") notFound();

  const gosterilecekBelge = belge ?? YEDEK_VERI_SILME_BELGESI;
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
