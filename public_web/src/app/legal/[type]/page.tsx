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

const GECERLI_TURLER = ["privacy", "terms", "consent"] as const;
type GecerliTur = (typeof GECERLI_TURLER)[number];

const BASLIK: Record<GecerliTur, string> = {
  privacy: "Aydınlatma Metni",
  terms: "Kullanım Şartları",
  consent: "Açık Rıza Beyanı",
};

interface LegalSection {
  title?: string;
  body?: string;
}

interface Params {
  params: Promise<{ type: string }>;
}

function gecerliTurMu(deger: string): deger is GecerliTur {
  return (GECERLI_TURLER as readonly string[]).includes(deger);
}

async function belgeyiGetir(tur: GecerliTur) {
  const { data } = await supabase
    .from("legal_documents")
    .select("title, subtitle, sections, version")
    .eq("document_type", tur)
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
  if (!belge) notFound();

  const sections = Array.isArray(belge.sections)
    ? (belge.sections as LegalSection[])
    : [];

  return (
    <main
      style={{
        maxWidth: 720,
        margin: "0 auto",
        padding: "40px 20px",
        color: "#EDEDED",
        fontFamily: "system-ui",
      }}
    >
      <h1>{belge.title || BASLIK[type]}</h1>
      {belge.subtitle ? <p>{belge.subtitle}</p> : null}

      {sections.map((section, index) => (
        <section key={index}>
          {section.title ? <h2>{section.title}</h2> : null}
          {section.body ? <p style={{ whiteSpace: "pre-wrap" }}>{section.body}</p> : null}
        </section>
      ))}

      <p style={{ opacity: 0.6, fontSize: 13, marginTop: 32 }}>
        Sürüm: {belge.version}
      </p>
    </main>
  );
}
