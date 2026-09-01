"use client";

import Link from "next/link";
import Image from "next/image";
import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { KesfetYanMenu } from "@/components/kesfet/KesfetYanMenu";
import { OnayIkonu, StorefrontIkonu } from "@/components/site/icons";
import { FIELD_BY_KEY } from "@/lib/vitrinFieldSchema";
import { safeParseJson } from "@/lib/products";
import { gpsAdresiniCoz } from "@/lib/konumCozumleme";
import { OwnerProductManager, type OwnerProduct, type OwnerProductCategory } from "./OwnerProductManager";
import { AboutEditor } from "@/app/v/[slug]/components/AboutEditor";
import { CampaignEditor } from "@/app/v/[slug]/components/CampaignEditor";
import { FaqEditor } from "@/app/v/[slug]/components/FaqEditor";
import { GalleryEditor } from "@/app/v/[slug]/components/GalleryEditor";
import { MarketplaceEditor } from "@/app/v/[slug]/components/MarketplaceEditor";

type Draft = Record<string, unknown>;

interface Props {
  store: {
    slug: string;
    name: string;
    is_published: boolean;
    products: OwnerProduct[];
    product_categories: OwnerProductCategory[];
  };
  initialDraft: Draft;
  onRefresh: () => Promise<void>;
}

type FieldSpec = {
  key: string;
  label: string;
  placeholder?: string;
  kind?: "text" | "textarea" | "url" | "email" | "tel" | "select";
  required?: boolean;
  options?: readonly string[];
};

const SECTIONS: Array<{ title: string; required?: boolean; fields: FieldSpec[] }> = [
  {
    title: "Kimlik",
    required: true,
    fields: [
      { key: "isletmeAdi", label: "İşletme / Vixrex Adı", placeholder: "Örn: Aymira Butik", required: true },
      { key: "isletmeTuru", label: "İşletme Türü", placeholder: "Örn: Butik" },
      { key: "kisaTanitim", label: "Kısa Açıklama", placeholder: "Bugün vitrinde ne var? Kısa bir tanıtım yaz.", kind: "textarea" },
      { key: "heroRozet", label: "Kapak Rozeti", placeholder: "Örn: Atölye / Mağaza" },
      { key: "logo", label: "Logo", placeholder: "Logo görsel bağlantısı", kind: "url" },
    ],
  },
  {
    title: "İletişim",
    required: true,
    fields: [
      { key: "whatsapp", label: "WhatsApp", placeholder: "05xx xxx xx xx", kind: "tel", required: true },
      { key: "telefon", label: "Telefon", placeholder: "05xx xxx xx xx", kind: "tel" },
      { key: "eposta", label: "E-posta", placeholder: "iletisim@isletme.com", kind: "email" },
      { key: "instagram", label: "Instagram", placeholder: "kullaniciadi" },
    ],
  },
  {
    title: "Konum ve saatler",
    required: true,
    fields: [
      { key: "adres", label: "Açık Adres", placeholder: "Mahalle, cadde, bina no", kind: "textarea", required: true },
      { key: "il", label: "İl", placeholder: "Örn: İstanbul", required: true },
      { key: "ilce", label: "İlçe", placeholder: "Örn: Kadıköy", required: true },
      { key: "mahalle", label: "Mahalle", placeholder: "Örn: Caddebostan" },
      { key: "konumMetni", label: "Vitrin Konum Metni", placeholder: "Örn: Kadıköy, İstanbul" },
      { key: "haritaEtiketi", label: "Harita Kartı Etiketi", placeholder: "Örn: Çarşı içi" },
      { key: "calismaSaatleri", label: "Çalışma Saatleri", placeholder: "Pzt–Cmt 09.00–19.00", kind: "textarea" },
      { key: "enlem", label: "Enlem", placeholder: "41.015", kind: "text" },
      { key: "boylam", label: "Boylam", placeholder: "28.978", kind: "text" },
    ],
  },
  {
    title: "Görseller",
    fields: [
      {
        key: "kategori",
        label: "İşletme Kategorisi",
        kind: "select",
        required: true,
        options: FIELD_BY_KEY.get("kategori")?.secenekler ?? [],
      },
      { key: "kapakGorseli", label: "Kapak Görseli", placeholder: "Görsel bağlantısı", kind: "url" },
      { key: "galeriUstBaslik", label: "Galeri Üst Başlığı", placeholder: "Örn: İşlerimizden" },
      { key: "galeriBaslik", label: "Galeri Başlığı", placeholder: "Örn: Galerimiz" },
      { key: "galeriAksiyonMetni", label: "Galeri Buton Metni", placeholder: "Örn: Hepsini gör" },
      { key: "galeriAksiyonLinki", label: "Galeri Buton Bağlantısı", kind: "url", placeholder: "https://" },
    ],
  },
  {
    title: "İçerik ve SEO",
    fields: [
      { key: "hakkindaMetin", label: "Hakkımızda Yazısı", kind: "textarea", placeholder: "İşletmenizin hikâyesini anlatın" },
      { key: "kategoriBolumBaslik", label: "Kategori Bölümü Başlığı", placeholder: "Kategoriler" },
      { key: "urunBolumBaslik", label: "Ürün Bölümü Başlığı", placeholder: "Ürünler" },
      { key: "blogUstBaslik", label: "Blog Üst Başlığı", placeholder: "Bilgi köşesi" },
      { key: "blogBaslik", label: "Blog Başlığı", placeholder: "Yazılar" },
      { key: "sssUstBaslik", label: "SSS Üst Başlığı", placeholder: "Merak edilenler" },
      { key: "sssBaslik", label: "SSS Bölüm Başlığı", placeholder: "Sıkça sorulan sorular" },
      { key: "sssAciklama", label: "SSS Bölüm Açıklaması", kind: "textarea", placeholder: "Müşterilerinizin sık sorduğu konular" },
      { key: "haritaLinki", label: "Google İşletme Bağlantısı", kind: "url", placeholder: "https://" },
      { key: "referansLinki", label: "Referanslar Bağlantısı", kind: "url", placeholder: "https://" },
    ],
  },
];

function valueFor(draft: Draft, key: string): string {
  const column = FIELD_BY_KEY.get(key)?.kolon ?? key;
  const value = draft[column];
  return typeof value === "string" || typeof value === "number" ? String(value) : "";
}

function filled(value: unknown): boolean {
  if (Array.isArray(value)) return value.length > 0;
  return typeof value === "string" ? value.trim().length > 0 : Boolean(value);
}

export function VitrinimEditor({ store, initialDraft, onRefresh }: Props) {
  const router = useRouter();
  const [draft, setDraft] = useState<Draft>({ name: store.name, ...initialDraft });
  const [openSection, setOpenSection] = useState(0);
  const [query, setQuery] = useState("");
  const [savingKey, setSavingKey] = useState<string | null>(null);
  const [publishing, setPublishing] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [locating, setLocating] = useState(false);
  const [legalAccepted, setLegalAccepted] = useState(() => Boolean(
    initialDraft.privacy_notice_version &&
    initialDraft.terms_version &&
    initialDraft.publication_consent_accepted
  ));
  const [message, setMessage] = useState("");
  const [activeEditor, setActiveEditor] = useState<"about" | "campaign" | "faq" | "gallery" | "marketplace" | null>(null);

  useEffect(() => {
    let active = true;
    async function syncDraft() {
      await Promise.resolve();
      if (active) setDraft({ name: store.name, ...initialDraft });
    }
    void syncDraft();
    return () => { active = false; };
  }, [initialDraft, store.name]);

  const progress = useMemo(() => {
    const count = (keys: string[]) => keys.filter((key) => {
      const column = FIELD_BY_KEY.get(key)?.kolon ?? key;
      return filled(draft[column]);
    }).length;
    const counts = [
      { done: count(["isletmeAdi", "kategori", "isletmeTuru", "kisaTanitim", "heroRozet", "logo"]), total: 6 },
      { done: count(["whatsapp", "telefon", "eposta", "instagram"]), total: 4 },
      { done: count(["adres", "il", "ilce", "mahalle", "konumMetni", "haritaEtiketi", "calismaSaatleri", "enlem", "boylam"]), total: 9 },
      { done: count(["kapakGorseli", "gallery_items", "galeriUstBaslik", "galeriBaslik", "galeriAksiyonMetni", "galeriAksiyonLinki"]), total: 6 },
      {
        done:
          count(["hakkindaMetin", "featured_banner_title", "faq_items", "blogUstBaslik", "blogBaslik", "haritaLinki", "marketplace_links", "referansLinki", "kategoriBolumBaslik", "urunBolumBaslik"])
          + (store.products?.length ? 1 : 0)
          + 1,
        total: 12,
      },
    ];
    const done = counts.reduce((sum, item) => sum + item.done, 0);
    const total = counts.reduce((sum, item) => sum + item.total, 0);
    return { counts, done, total, percent: total ? Math.round((done / total) * 100) : 0 };
  }, [draft, store.products]);

  const missing = [
    ["isletmeAdi", "İşletme adı"],
    ["kategori", "Kategori"],
    ["whatsapp", "WhatsApp"],
    ["adres", "Adres"],
    ["il", "İl"],
    ["ilce", "İlçe"],
  ].filter(([key]) => !filled(valueFor(draft, key))).map(([, label]) => label);

  function updateLocal(key: string, value: string) {
    const column = FIELD_BY_KEY.get(key)?.kolon ?? key;
    setDraft((current) => ({ ...current, [column]: value }));
  }

  async function save(key: string) {
    setSavingKey(key);
    setMessage("");
    try {
      const response = await fetch("/api/owner-draft", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: store.slug, anahtar: key, deger: valueFor(draft, key) || null, clientId: null }),
      });
      const body = await response.json();
      if (!response.ok) throw new Error(body?.hata ?? "Kaydedilemedi.");
      setMessage("Değişiklik kaydedildi.");
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Değişiklik kaydedilemedi.");
    } finally {
      setSavingKey(null);
    }
  }

  async function publish() {
    setPublishing(true);
    setMessage("");
    try {
      const response = await fetch("/api/owner-publish", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: store.slug }),
      });
      const body = await response.json();
      if (!response.ok) throw new Error(body?.hata ?? "Vitrin yayınlanamadı.");
      setMessage("Vitrinin yayınlandı.");
      await onRefresh();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Vitrin yayınlanamadı.");
    } finally {
      setPublishing(false);
    }
  }

  async function acceptLegal() {
    setPublishing(true);
    setMessage("");
    try {
      const response = await fetch("/api/owner-accept-legal", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: store.slug }),
      });
      const body = await response.json();
      if (!response.ok) throw new Error(body?.hata ?? "Yasal onay kaydedilemedi.");
      setLegalAccepted(true);
      setMessage("Yasal onayın kaydedildi.");
      await onRefresh();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Yasal onay kaydedilemedi.");
    } finally {
      setPublishing(false);
    }
  }

  async function uploadGorsel(file: File, anahtar: string) {
    setUploading(true);
    setMessage("");
    try {
      const form = new FormData();
      form.append("slug", store.slug);
      form.append("anahtar", anahtar);
      form.append("dosya", file);
      const uploadResponse = await fetch("/api/owner-upload", { method: "POST", body: form });
      const uploadBody = await uploadResponse.json();
      if (!uploadResponse.ok) throw new Error(uploadBody?.hata ?? "Görsel yüklenemedi.");
      updateLocal(anahtar, uploadBody.url);
      const saveResponse = await fetch("/api/owner-draft", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: store.slug, anahtar, deger: uploadBody.url, clientId: null }),
      });
      const saveBody = await saveResponse.json();
      if (!saveResponse.ok) throw new Error(saveBody?.hata ?? "Görsel kaydedilemedi.");
      setMessage(`${FIELD_BY_KEY.get(anahtar)?.etiket ?? "Görsel"} kaydedildi.`);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Görsel yüklenemedi.");
    } finally {
      setUploading(false);
    }
  }

  async function uploadCover(file: File) {
    return uploadGorsel(file, "kapakGorseli");
  }

  async function konumuAl() {
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      setMessage("Tarayıcı konum desteği vermiyor.");
      return;
    }
    setLocating(true);
    setMessage("");
    try {
      const pos = await new Promise<GeolocationPosition>((resolve, reject) =>
        navigator.geolocation.getCurrentPosition(resolve, reject, { enableHighAccuracy: true, timeout: 10000 }),
      );
      const lat = pos.coords.latitude.toFixed(6);
      const lng = pos.coords.longitude.toFixed(6);
      updateLocal("enlem", lat);
      updateLocal("boylam", lng);
      // Enlem/boylamı hemen kaydet — tek tek save çağrısı gerekli (validateField sayi tipi)
      await save("enlem");
      await save("boylam");
      try {
        const cozum = await gpsAdresiniCoz(Number(lat), Number(lng));
        if (cozum.provinceName) {
          updateLocal("il", cozum.provinceName);
          await save("il");
        }
        if (cozum.districtName) {
          updateLocal("ilce", cozum.districtName);
          await save("ilce");
        }
        // Adres boşsa reverse-geocode adresini doldur, doluysa dokunma (kullanıcı elle yazmış olabilir)
        const mevcutAdres = valueFor(draft, "adres").trim();
        if (!mevcutAdres && cozum.address) {
          updateLocal("adres", cozum.address);
          await save("adres");
        }
        // Mahalle reverse sonuçta suburb olarak gelebiliyor ama gpsAdresiniCoz mahalleyi ayrı döndürmüyor;
        // adres içinde zaten var, ek alan olarak ayrıca doldurmuyoruz — kullanıcı gerekirse elle ekler
        setMessage("Konum alındı — enlem/boylam ve il/ilçe güncellendi.");
      } catch (e) {
        setMessage(e instanceof Error ? e.message : "Konum alındı, adres çözümlenemedi. Enlem/boylam kaydedildi.");
      }
    } catch (e) {
      const msg = e instanceof GeolocationPositionError ? e.message : "Konum alınamadı. İzin verin ve tekrar deneyin.";
      setMessage(msg);
    } finally {
      setLocating(false);
    }
  }

  async function closeStructuredEditor() {
    setActiveEditor(null);
    await onRefresh();
  }

  const galleryItems = safeParseJson<{ id?: string; imageUrl: string; title?: string }>(draft.gallery_items);
  const faqItems = safeParseJson<{ id?: string; question?: string; answer?: string }>(draft.faq_items).map((item, index) => ({
    id: String(item.id || `faq-${index + 1}`),
    question: String(item.question || ""),
    answer: String(item.answer || ""),
  }));
  const marketplaceLinks = safeParseJson<{ id?: string; platform?: string; url?: string; subtitle?: string }>(draft.marketplace_links).map((item, index) => ({
    id: String(item.id || `marketplace-${index + 1}`),
    platform: String(item.platform || ""),
    url: String(item.url || ""),
    subtitle: String(item.subtitle || ""),
  }));
  const aboutValues = safeParseJson<{ id?: string; title?: string; description?: string }>(draft.about_values).map((item, index) => ({
    id: String(item.id || `about-${index + 1}`),
    title: String(item.title || ""),
    description: String(item.description || ""),
  }));

  const editorButtonClass = "min-h-11 rounded-xl border border-lp-border bg-lp-surface px-4 text-[13px] font-black text-lp-text hover:border-lp-primary hover:text-lp-secondary";

  return (
    <main className="min-h-screen bg-lp-bg-editor text-lp-text">
      <div className="flex min-h-screen">
        <KesfetYanMenu
          sorgu={query}
          sorguyuDegistir={setQuery}
          aktifBolum="vitrinim"
          vixrexAc={() => router.push("/kesfet?vixrex=1")}
        />
        <div className="min-w-0 flex-1">
          <header className="sticky top-0 z-20 flex min-h-[61px] items-center justify-between gap-4 border-b border-lp-border bg-lp-bg-light/95 px-5 backdrop-blur sm:px-8">
            <div className="flex min-w-0 items-center gap-3 text-[12px] font-bold">
              <span className={`rounded-full border px-3 py-1 ${store.is_published ? "border-emerald-500/50 text-emerald-300" : "border-lp-border text-lp-muted"}`}>
                {store.is_published ? "Yayında" : "Yayında değil"}
              </span>
              <span className="truncate text-lp-muted">{store.is_published ? "Vitrinin müşterilere açık" : "Vitrinini henüz yayınlamadın"}</span>
            </div>
            <button type="button" onClick={publish} disabled={publishing} className="min-h-10 shrink-0 rounded-xl bg-lp-primary px-5 text-[13px] font-black text-white transition hover:bg-lp-secondary disabled:opacity-60">
              {publishing ? "Yayınlanıyor…" : store.is_published ? "Yeniden yayınla" : "Vitrini yayınla"}
            </button>
          </header>

          <div className="mx-auto w-full max-w-[1264px] px-4 py-8 sm:px-8">
            <div className="mb-2 flex items-center justify-between gap-4">
              <h1 className="text-[24px] font-black leading-tight">{store.is_published ? "Vixrex Düzenle" : "Vixrex Oluştur"}</h1>
              <button type="button" onClick={() => router.push("/kesfet?vixrex=1")} className="min-h-8 shrink-0 rounded-full bg-lp-primary px-4 text-[12px] font-black text-white hover:bg-lp-secondary">
                <span className="flex items-center gap-1.5"><StorefrontIkonu boyut={13} /> Vixrex ile</span>
              </button>
            </div>
            <p className="mb-4 text-[13px] font-semibold text-lp-muted">
              {store.is_published
                ? "Düzenledikten sonra kaydet, linkin ve QR kodun güncellenir."
                : "Ad, WhatsApp ve konumunu gir — vitrin hazır. Diğer detayları sonra ekleyebilirsin."}
            </p>
            <p className="mb-2 text-[12px] font-bold text-lp-muted">Paylaşım linki</p>
            <div className="mb-4 flex min-h-12 items-center rounded-2xl border border-lp-border bg-lp-surface px-4 text-[13px] font-semibold text-lp-muted">
              {valueFor(draft, "isletmeAdi") ? (
                <Link href={`/v/${store.slug}`} target="_blank" className="truncate text-lp-text hover:text-lp-secondary">vixrex.com/v/{store.slug}</Link>
              ) : "İşletme adı yazınca oluşur."}
            </div>

            <section className="overflow-hidden rounded-2xl border border-lp-border bg-lp-bg-light" aria-labelledby="vitrinim-editor-title">
              <div className="border-b border-lp-border px-6 py-5">
                <div className="flex items-center justify-between gap-4">
                  <h1 id="vitrinim-editor-title" className="text-xl font-black">Vitrinim</h1>
                  <span className="text-[13px] font-black text-lp-secondary">%{progress.percent} hazır</span>
                </div>
                <div className="mt-3 h-1.5 overflow-hidden rounded-full bg-lp-surface-soft"><div className="h-full rounded-full bg-lp-primary transition-all" style={{ width: `${progress.percent}%` }} /></div>
                <p className="mt-3 text-[12px] font-medium text-lp-muted">
                  {missing.length ? `Yayına çıkmak için ${missing.join(", ")} ve Yasal onay alanları kaldı.` : "Temel bilgiler hazır. Yasal onaydan sonra yayınlayabilirsin."}
                </p>
              </div>

              {message ? <p className="mx-6 mt-4 rounded-xl border border-lp-border bg-lp-surface px-4 py-3 text-[12px] text-lp-text" role="status">{message}</p> : null}

              <div className="grid lg:grid-cols-2">
                {SECTIONS.map((section, index) => {
                  const count = progress.counts[index];
                  const isOpen = openSection === index;
                  return (
                    <section key={section.title} className="border-b border-lp-border lg:[&:nth-child(odd)]:border-r">
                      <button type="button" onClick={() => setOpenSection(isOpen ? -1 : index)} className="flex min-h-[76px] w-full items-center gap-3 px-6 text-left hover:bg-lp-surface/45" aria-expanded={isOpen}>
                        <span className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full border text-[13px] font-bold ${count.done === count.total ? "border-emerald-500 bg-emerald-500/15 text-emerald-300" : "border-lp-border bg-lp-surface-soft text-lp-secondary"}`}>{index + 1}</span>
                        <span className="min-w-0 flex-1">
                          <span className="block text-[16px] font-black">{section.title}</span>
                          <span className="mt-0.5 block text-[12px] font-semibold text-lp-muted">{count.done} / {count.total} alan dolu{section.required ? " · zorunlu" : ""}</span>
                        </span>
                        <span className="text-[12px] font-bold text-lp-muted">{isOpen ? "Kapat" : "Aç"}</span>
                      </button>

                      {isOpen ? (
                        <div className="space-y-4 px-6 pb-6">
                          {section.fields.map((field) => {
                            const id = `vitrin-${field.key}`;
                            const value = valueFor(draft, field.key);
                            const common = "min-h-12 w-full rounded-xl border border-lp-border bg-lp-surface px-4 text-[14px] font-semibold text-lp-text outline-none transition placeholder:text-lp-muted/70 focus:border-lp-primary focus:ring-2 focus:ring-lp-primary/25";
                            return (
                              <div key={field.key}>
                                <label htmlFor={id} className="mb-2 block text-[12px] font-bold text-lp-muted">{field.label}{field.required ? <span className="text-lp-primary"> *</span> : null}</label>
                                {field.key === "kapakGorseli" || field.key === "logo" ? (
                                  <div className="space-y-3">
                                    {value ? (
                                      <div className="relative h-32 w-full overflow-hidden rounded-xl border border-lp-border">
                                        <Image src={value} alt={`${field.label} önizlemesi`} fill sizes="(max-width: 1024px) 100vw, 540px" className="object-cover" />
                                      </div>
                                    ) : null}
                                    <label htmlFor={id} className="flex min-h-12 cursor-pointer items-center justify-center rounded-xl border border-dashed border-lp-border bg-lp-surface px-4 text-[13px] font-black text-lp-secondary hover:border-lp-primary">
                                      {uploading ? "Yükleniyor…" : value ? `${field.label} değiştir` : `${field.label} yükle`}
                                    </label>
                                    <input id={id} type="file" accept="image/jpeg,image/png,image/webp" disabled={uploading} onChange={(event) => { const file = event.target.files?.[0]; if (file) void uploadGorsel(file, field.key); }} className="sr-only" />
                                  </div>
                                ) : field.kind === "textarea" ? (
                                  <textarea id={id} value={value} placeholder={field.placeholder} onChange={(event) => updateLocal(field.key, event.target.value)} onBlur={() => save(field.key)} className={`${common} min-h-24 resize-y py-3`} />
                                ) : field.kind === "select" ? (
                                  <select id={id} value={value} onChange={(event) => { updateLocal(field.key, event.target.value); }} onBlur={() => save(field.key)} className={common}>
                                    <option value="">Seçiniz</option>
                                    {field.options?.map((option) => <option key={option} value={option}>{option}</option>)}
                                  </select>
                                ) : (
                                  <input id={id} type={field.kind ?? "text"} value={value} placeholder={field.placeholder} onChange={(event) => updateLocal(field.key, event.target.value)} onBlur={() => save(field.key)} className={common} />
                                )}
                                {savingKey === field.key ? <span className="mt-1 block text-right text-[11px] font-semibold text-lp-secondary">Kaydediliyor…</span> : null}
                              </div>
                            );
                          })}

                           {section.title === "İçerik ve SEO" ? (
                             <div className="space-y-6 pt-2">
                               <div className="space-y-4">
                                 <h3 className="text-[13px] font-black text-lp-text">Hakkımızda</h3>
                                 <AboutEditor inline slug={store.slug} mevcut={{ kicker: String(draft.about_kicker || ""), title: String(draft.about_title || ""), body: String(draft.corporate_bio || ""), imageUrl: String(draft.about_image_url || ""), imageCaption: String(draft.about_image_caption || ""), values: aboutValues }} onClose={() => { void onRefresh(); }} />
                               </div>
                               <div className="space-y-4">
                                 <h3 className="text-[13px] font-black text-lp-text">Öne çıkan kampanya</h3>
                                 <CampaignEditor inline slug={store.slug} mevcut={{ label: String(draft.featured_banner_label || ""), title: String(draft.featured_banner_title || ""), description: String(draft.featured_banner_description || ""), priceText: String(draft.featured_banner_price_text || ""), imageUrl: String(draft.featured_banner_image_url || "") }} onClose={() => { void onRefresh(); }} />
                               </div>
                               <div className="space-y-4">
                                 <h3 className="text-[13px] font-black text-lp-text">Sık sorulanlar</h3>
                                 <FaqEditor inline slug={store.slug} items={faqItems} onClose={() => { void onRefresh(); }} />
                               </div>
                               <div className="space-y-4">
                                 <h3 className="text-[13px] font-black text-lp-text">Pazar yeri bağlantıları</h3>
                                 <MarketplaceEditor inline slug={store.slug} links={marketplaceLinks} onClose={() => { void onRefresh(); }} />
                               </div>
                               <Link href={`/v/${store.slug}/blog-yonetim`} className={`${editorButtonClass} flex items-center justify-center`}>Blog yönetimi</Link>
                               <p className="mb-3 text-[12px] font-bold text-lp-muted">Ürünler ve kategoriler</p>
                               <OwnerProductManager storeSlug={store.slug} products={store.products ?? []} categories={store.product_categories ?? []} onRefresh={onRefresh} />
                             </div>
                           ) : null}
                            {section.title === "Konum ve saatler" ? (
                              <button type="button" onClick={() => void konumuAl()} disabled={locating} className={`${editorButtonClass} w-full`}>
                                {locating ? "Konum alınıyor…" : "📍 Konumumu al (GPS)"}
                              </button>
                            ) : null}
                            {section.title === "Görseller" ? (
                              <div className="pt-2">
                                <h3 className="mb-3 text-[13px] font-black text-lp-text">Galeri</h3>
                                <GalleryEditor inline slug={store.slug} items={galleryItems} onClose={() => { void onRefresh(); }} />
                              </div>
                            ) : null}
                        </div>
                      ) : null}
                    </section>
                  );
                })}
              </div>

              <div className="px-6 py-6">
                <div className={`rounded-[18px] border bg-lp-surface p-4 ${legalAccepted ? "border-lp-primary" : "border-lp-border"}`}>
                  <h2 className="flex items-center gap-2 text-[16px] font-black"><OnayIkonu boyut={20} className="text-lp-primary" /> Yasal Bilgilendirme ve Yayınlama Onayı</h2>
                  <p className="mt-2 text-[12px] font-medium leading-5 text-lp-muted">Taslağınızı onay vermeden düzenleyebilirsiniz. Bu beyanlar yalnızca herkese açık yayınlama için gereklidir.</p>
                  <label className="mt-4 flex cursor-pointer items-start gap-3 text-[12.5px] font-semibold leading-5 text-lp-text">
                    <input type="checkbox" checked={legalAccepted} disabled={legalAccepted || publishing} onChange={() => { if (!legalAccepted) void acceptLegal(); }} className="mt-0.5 h-5 w-5 shrink-0 accent-[#147DFF]" />
                    <span>
                      <Link href="/legal/privacy" target="_blank" className="font-bold text-lp-secondary underline">Aydınlatma Metni</Link>,{" "}
                      <Link href="/legal/terms" target="_blank" className="font-bold text-lp-secondary underline">Kullanım Şartları</Link> ve{" "}
                      <Link href="/legal/consent" target="_blank" className="font-bold text-lp-secondary underline">Açık Rıza Beyanı</Link>&apos;nı okudum, anladım ve kabul ediyorum.
                    </span>
                  </label>
                </div>
                <button type="button" onClick={publish} disabled={publishing || !legalAccepted} className="mt-4 min-h-[54px] w-full rounded-2xl bg-lp-primary px-5 text-[15px] font-black text-white disabled:bg-lp-surface-soft disabled:text-lp-muted disabled:opacity-70">
                  {publishing ? "Yayına alınıyor…" : store.is_published ? "Değişiklikleri Kaydet & Yayına Al" : "Vitrinimi Yayına Al"}
                </button>
                <p className="mt-2 text-center text-[12px] font-semibold text-lp-muted">
                  {store.is_published ? "Mevcut linkin korunur, Keşfet görünümün güncellenir." : "Linkin oluşur, Keşfet'te görünürsün."}
                </p>
              </div>
            </section>
          </div>
        </div>
      </div>

      {activeEditor === "gallery" ? <GalleryEditor slug={store.slug} items={galleryItems} onClose={() => { void closeStructuredEditor(); }} /> : null}
      {activeEditor === "faq" ? <FaqEditor slug={store.slug} items={faqItems} onClose={() => { void closeStructuredEditor(); }} /> : null}
      {activeEditor === "marketplace" ? <MarketplaceEditor slug={store.slug} links={marketplaceLinks} onClose={() => { void closeStructuredEditor(); }} /> : null}
      {activeEditor === "about" ? (
        <AboutEditor
          slug={store.slug}
          mevcut={{
            kicker: String(draft.about_kicker || ""),
            title: String(draft.about_title || ""),
            body: String(draft.corporate_bio || ""),
            imageUrl: String(draft.about_image_url || ""),
            imageCaption: String(draft.about_image_caption || ""),
            values: aboutValues,
          }}
          onClose={() => { void closeStructuredEditor(); }}
        />
      ) : null}
      {activeEditor === "campaign" ? (
        <CampaignEditor
          slug={store.slug}
          mevcut={{
            label: String(draft.featured_banner_label || ""),
            title: String(draft.featured_banner_title || ""),
            description: String(draft.featured_banner_description || ""),
            priceText: String(draft.featured_banner_price_text || ""),
            imageUrl: String(draft.featured_banner_image_url || ""),
          }}
          onClose={() => { void closeStructuredEditor(); }}
        />
      ) : null}
    </main>
  );
}
