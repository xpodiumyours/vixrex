"use client";

import Link from "next/link";
import Image from "next/image";
import { useEffect, useMemo, useState } from "react";
import { OnayIkonu, StorefrontIkonu } from "@/components/site/icons";
import { useAppShell } from "@/components/app/AppShellContext";
import { VitrinPaylasimKarti } from "@/components/owner/VitrinPaylasimKarti";\nimport { OwnerDashboardMetrics } from "@/components/owner/OwnerDashboardMetrics";
import { FIELD_BY_KEY } from "@/lib/vitrinFieldSchema";
import { safeParseJson } from "@/lib/products";
import { gpsAdresiniCoz } from "@/lib/konumCozumleme";
import { OwnerProductManager, type OwnerProduct, type OwnerProductCategory } from "./OwnerProductManager";
import { isletmeUrunSablonu } from "@/lib/businessCategories";
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
    kategori?: string | null;
    business_type?: string | null;
    products: OwnerProduct[];
    product_categories: OwnerProductCategory[];
  };
  initialDraft: Draft;
  onRefresh: () => Promise<void>;
  isCreationMode?: boolean;
  onCreate?: (draft: Draft) => Promise<void>;
}

function alanEtiketi(field: { key: string; label?: string }): string {
  return field.label ?? FIELD_BY_KEY.get(field.key)?.etiket ?? field.key;
}

type FieldSpec = {
  key: string;
  /** Şemada karşılığı olmayan alanlar için elle etiket. Şemadaki alanlar
   *  etiketini `vitrinFieldSchema`'dan alır — iki istemci aynı ismi görsün. */
  label?: string;
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
      { key: "isletmeAdi", placeholder: "Örn: Aymira Butik", required: true },
      { key: "isletmeTuru", placeholder: "Örn: Butik" },
      { key: "kisaTanitim", placeholder: "Bugün vitrinde ne var? Kısa bir tanıtım yaz.", kind: "textarea" },
      { key: "heroRozet", placeholder: "Örn: Atölye / Mağaza" },
      { key: "logo", placeholder: "Logo görsel bağlantısı", kind: "url" },
    ],
  },
  {
    title: "İletişim",
    required: true,
    fields: [
      { key: "whatsapp", placeholder: "05xx xxx xx xx", kind: "tel", required: true },
      { key: "telefon", placeholder: "05xx xxx xx xx", kind: "tel" },
      { key: "eposta", placeholder: "iletisim@isletme.com", kind: "email" },
      { key: "instagram", placeholder: "kullaniciadi" },
    ],
  },
  {
    title: "Konum ve saatler",
    required: true,
    fields: [
      { key: "adres", placeholder: "Mahalle, cadde, bina no", kind: "textarea", required: true },
      { key: "il", placeholder: "Örn: İstanbul", required: true },
      { key: "ilce", placeholder: "Örn: Kadıköy", required: true },
      { key: "mahalle", placeholder: "Örn: Caddebostan" },
      { key: "konumMetni", placeholder: "Örn: Kadıköy, İstanbul" },
      { key: "haritaEtiketi", placeholder: "Örn: Çarşı içi" },
      { key: "calismaSaatleri", placeholder: "Pzt–Cmt 09.00–19.00", kind: "textarea" },
      { key: "enlem", placeholder: "41.015", kind: "text" },
      { key: "boylam", placeholder: "28.978", kind: "text" },
    ],
  },
  {
    title: "Görseller",
    fields: [
      {
        key: "kategori",
        kind: "select",
        required: true,
        options: FIELD_BY_KEY.get("kategori")?.secenekler ?? [],
      },
      { key: "kapakGorseli", placeholder: "Görsel bağlantısı", kind: "url" },
      { key: "galeriUstBaslik", placeholder: "Örn: İşlerimizden" },
      { key: "galeriBaslik", placeholder: "Örn: Galerimiz" },
      { key: "galeriAksiyonMetni", placeholder: "Örn: Hepsini gör" },
      { key: "galeriAksiyonLinki", kind: "url", placeholder: "https://" },
    ],
  },
  {
    title: "İçerik ve SEO",
    fields: [
      { key: "hakkindaMetin", kind: "textarea", placeholder: "İşletmenizin hikâyesini anlatın" },
      { key: "kategoriBolumBaslik", placeholder: "Kategoriler" },
      { key: "urunBolumBaslik", placeholder: "Ürünler" },
      { key: "blogUstBaslik", placeholder: "Bilgi köşesi" },
      { key: "blogBaslik", placeholder: "Yazılar" },
      { key: "sssUstBaslik", placeholder: "Merak edilenler" },
      { key: "sssBaslik", placeholder: "Sıkça sorulan sorular" },
      { key: "sssAciklama", kind: "textarea", placeholder: "Müşterilerinizin sık sorduğu konular" },
      { key: "haritaLinki", kind: "url", placeholder: "https://" },
      { key: "referansLinki", kind: "url", placeholder: "https://" },
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

export function VitrinimEditor({ store, initialDraft, onRefresh, isCreationMode = false, onCreate }: Props) {
  const { refreshShellStatus } = useAppShell();
  const [draft, setDraft] = useState<Draft>({ name: store.name, ...initialDraft });
  const [openSection, setOpenSection] = useState(0);
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

  // Zorunlu alan adları da şemadan gelir: iki istemci aynı ismi söylesin.
  const missing = ["isletmeAdi", "kategori", "whatsapp", "adres", "il", "ilce"]
    .filter((key) => !filled(valueFor(draft, key)))
    .map((key) => alanEtiketi({ key }));

  function updateLocal(key: string, value: string) {
    const column = FIELD_BY_KEY.get(key)?.kolon ?? key;
    setDraft((current) => ({ ...current, [column]: value }));
  }

  async function save(key: string) {
    if (isCreationMode) {
      setMessage("Taslak güncellendi — yayınlayınca kaydedilecek.");
      return;
    }
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
    if (isCreationMode && onCreate) {
      setPublishing(true);
      setMessage("");
      try {
        await onCreate(draft);
        refreshShellStatus();
      } catch (error) {
        setMessage(error instanceof Error ? error.message : "Vitrin oluşturulamadı.");
      } finally {
        setPublishing(false);
      }
      return;
    }
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
      refreshShellStatus();
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
    if (isCreationMode) {
      setMessage("Görsel önizlemesi eklendi — vitrin oluşturulunca yüklenecek.");
      return;
    }
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
      await save("enlem");
      await save("boylam");
      try {
        const cozum = await gpsAdresiniCoz(Number(lat), Number(lng));
        if (cozum.provinceName) { updateLocal("il", cozum.provinceName); await save("il"); }
        if (cozum.districtName) { updateLocal("ilce", cozum.districtName); await save("ilce"); }
        const mevcutAdres = valueFor(draft, "adres").trim();
        if (!mevcutAdres && cozum.address) { updateLocal("adres", cozum.address); await save("adres"); }
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
  const faqItems = safeParseJson<{ id?: string; question?: string; answer?: string }>(draft.faq_items).map((item, index) => ({ id: String(item.id || `faq-${index + 1}`), question: String(item.question || ""), answer: String(item.answer || "") }));
  const marketplaceLinks = safeParseJson<{ id?: string; platform?: string; url?: string; subtitle?: string }>(draft.marketplace_links).map((item, index) => ({ id: String(item.id || `marketplace-${index + 1}`), platform: String(item.platform || ""), url: String(item.url || ""), subtitle: String(item.subtitle || "") }));
  const aboutValues = safeParseJson<{ id?: string; title?: string; description?: string }>(draft.about_values).map((item, index) => ({ id: String(item.id || `about-${index + 1}`), title: String(item.title || ""), description: String(item.description || "") }));

  const editorButtonClass = "min-h-11 rounded-xl border border-lp-border bg-lp-surface px-4 text-[13px] font-black text-lp-text hover:border-lp-primary hover:text-lp-secondary";

  return (
    <main className="min-w-0 flex-1 bg-lp-bg-editor text-lp-text">
      <div className="mx-auto w-full max-w-[1200px] px-4 py-[18px] min-[901px]:px-8 min-[901px]:py-7">
        <div className="mb-2 flex items-center justify-between gap-4">
          <h1 className="text-[24px] font-black leading-[1.15]">{store.is_published ? "Vixrex Düzenle" : "Vixrex Oluştur"}</h1>
          <span className="flex shrink-0 items-center gap-1 rounded-full bg-lp-primary px-2.5 py-[5px] text-[12px] font-extrabold text-lp-on-primary">
            <StorefrontIkonu boyut={13} /> Vixrex ile
          </span>
        </div>
        <p className="mb-4 text-[13px] font-semibold leading-[1.4] text-lp-muted">
          {store.is_published ? "Düzenledikten sonra kaydet, linkin ve QR kodun güncellenir." : "Ad, WhatsApp ve konumunu gir — vitrin hazır. Diğer detayları sonra ekleyebilirsin."}
        </p>

        {store.is_published && !isCreationMode ? <OwnerDashboardMetrics /> : null}

        <VitrinPaylasimKarti
          slug={store.slug}
          adVar={Boolean(valueFor(draft, "isletmeAdi").trim())}
          yayinda={store.is_published}
          olusturmaModu={isCreationMode}
          yayinaKaydir={() => document.getElementById("yasal-yayin-bolumu")?.scrollIntoView({ behavior: "smooth", block: "start" })}
        />

        <section className="mt-4 overflow-hidden rounded-2xl border border-lp-border bg-lp-surface" aria-labelledby="vitrinim-editor-title">
          <div className="border-b border-lp-border px-6 py-5">
            <div className="flex items-center justify-between gap-4">
              <h1 id="vitrinim-editor-title" className="text-[18px] font-black">Vitrinim</h1>
              <span className="text-[13px] font-black text-lp-secondary">%{progress.percent} hazır</span>
            </div>
            <div className="mt-3 h-1.5 overflow-hidden rounded-full bg-lp-surface-soft"><div className="h-full rounded-full bg-lp-primary transition-all" style={{ width: `${progress.percent}%` }} /></div>
            <p className="mt-3 text-[12px] font-medium text-lp-muted">{missing.length ? `Yayına çıkmak için ${missing.join(", ")} ve Yasal onay alanları kaldı.` : "Temel bilgiler hazır. Yasal onaydan sonra yayınlayabilirsin."}</p>
          </div>

          {message ? <p className="mx-6 mt-4 rounded-xl border border-lp-border bg-lp-bg-light px-4 py-3 text-[12px] text-lp-text" role="status">{message}</p> : null}

          <div className="grid min-[901px]:grid-cols-2">
            {SECTIONS.map((section, index) => {
              const count = progress.counts[index];
              const isOpen = openSection === index;
              return (
                <section key={section.title} className="border-b border-lp-border min-[901px]:[&:nth-child(odd)]:border-r">
                  <button type="button" onClick={() => setOpenSection(isOpen ? -1 : index)} className="flex min-h-[76px] w-full items-center gap-3 px-6 text-left hover:bg-lp-surface-soft/45" aria-expanded={isOpen}>
                    <span className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full border text-[13px] font-bold ${count.done === count.total ? "border-emerald-500 bg-emerald-500/15 text-emerald-300" : "border-lp-border bg-lp-surface-soft text-lp-secondary"}`}>{index + 1}</span>
                    <span className="min-w-0 flex-1"><span className="block text-[16px] font-black">{section.title}</span><span className="mt-0.5 block text-[12px] font-semibold text-lp-muted">{count.done} / {count.total} alan dolu{section.required ? " · zorunlu" : ""}</span></span>
                    <span className="text-[12px] font-bold text-lp-muted">{isOpen ? "Kapat" : "Aç"}</span>
                  </button>

                  {isOpen ? (
                    <div className="space-y-4 px-6 pb-6">
                      {section.fields.map((field) => {
                        const id = `vitrin-${field.key}`;
                        const value = valueFor(draft, field.key);
                        const common = "min-h-12 w-full rounded-xl border border-lp-border bg-lp-bg-light px-4 text-[14px] font-semibold text-lp-text outline-none transition placeholder:text-lp-muted/70 focus:border-lp-secondary focus:ring-2 focus:ring-lp-primary/25";
                        return (
                          <div key={field.key}>
                            <label htmlFor={id} className="mb-2 block text-[13px] font-bold text-lp-text-alt">{alanEtiketi(field)}{field.required ? <span className="text-lp-primary"> *</span> : null}</label>
                            {field.key === "kapakGorseli" || field.key === "logo" ? (
                              <div className="space-y-3">
                                {value ? <div className="relative aspect-[16/7] w-full overflow-hidden rounded-2xl border border-lp-border"><Image src={value} alt={`${alanEtiketi(field)} önizlemesi`} fill sizes="(max-width: 1024px) 100vw, 540px" className="object-cover" /></div> : null}
                                <label htmlFor={id} className="flex min-h-12 cursor-pointer items-center justify-center rounded-xl border border-lp-border bg-lp-bg-light px-4 text-[13px] font-black text-lp-secondary hover:border-lp-primary">{uploading ? "Yükleniyor…" : value ? `${alanEtiketi(field)} değiştir` : `${alanEtiketi(field)} yükle`}</label>
                                <input id={id} type="file" accept="image/jpeg,image/png,image/webp" disabled={uploading} onChange={(event) => { const file = event.target.files?.[0]; if (file) void uploadGorsel(file, field.key); }} className="sr-only" />
                              </div>
                            ) : field.kind === "textarea" ? (
                              <textarea id={id} value={value} placeholder={field.placeholder} onChange={(event) => updateLocal(field.key, event.target.value)} onBlur={() => save(field.key)} className={`${common} min-h-24 resize-y py-3`} />
                            ) : field.kind === "select" ? (
                              <select id={id} value={value} onChange={(event) => updateLocal(field.key, event.target.value)} onBlur={() => save(field.key)} className={common}><option value="">Seçiniz</option>{field.options?.map((option) => <option key={option} value={option}>{option}</option>)}</select>
                            ) : (
                              <input id={id} type={field.kind ?? "text"} value={value} placeholder={field.placeholder} onChange={(event) => updateLocal(field.key, event.target.value)} onBlur={() => save(field.key)} className={common} />
                            )}
                            {savingKey === field.key ? <span className="mt-1 block text-right text-[11px] font-semibold text-lp-secondary">Kaydediliyor…</span> : null}
                          </div>
                        );
                      })}

                      {section.title === "İçerik ve SEO" ? (
                        <div className="space-y-6 pt-2">
                          <div className="space-y-4"><h3 className="text-[13px] font-black text-lp-text">Hakkımızda</h3><AboutEditor inline slug={store.slug} mevcut={{ kicker: String(draft.about_kicker || ""), title: String(draft.about_title || ""), body: String(draft.corporate_bio || ""), imageUrl: String(draft.about_image_url || ""), imageCaption: String(draft.about_image_caption || ""), values: aboutValues }} onClose={() => { void onRefresh(); }} /></div>
                          <div className="space-y-4"><h3 className="text-[13px] font-black text-lp-text">Öne çıkan kampanya</h3><CampaignEditor inline slug={store.slug} mevcut={{ label: String(draft.featured_banner_label || ""), title: String(draft.featured_banner_title || ""), description: String(draft.featured_banner_description || ""), priceText: String(draft.featured_banner_price_text || ""), imageUrl: String(draft.featured_banner_image_url || "") }} onClose={() => { void onRefresh(); }} /></div>
                          <div className="space-y-4"><h3 className="text-[13px] font-black text-lp-text">Sık sorulanlar</h3><FaqEditor inline slug={store.slug} items={faqItems} onClose={() => { void onRefresh(); }} /></div>
                          <div className="space-y-4"><h3 className="text-[13px] font-black text-lp-text">Pazar yeri bağlantıları</h3><MarketplaceEditor inline slug={store.slug} links={marketplaceLinks} onClose={() => { void onRefresh(); }} /></div>
                          <Link href={`/v/${store.slug}/blog-yonetim`} className={`${editorButtonClass} flex items-center justify-center`}>Blog yönetimi</Link>
                          <p className="mb-3 text-[12px] font-bold text-lp-muted">Ürünler ve kategoriler</p>
                          <OwnerProductManager storeSlug={store.slug} products={store.products ?? []} categories={store.product_categories ?? []} varsayilanUrunTipi={isletmeUrunSablonu(store.kategori, store.business_type)} storeName={store.name} onRefresh={onRefresh} />
                        </div>
                      ) : null}
                      {section.title === "Konum ve saatler" ? <button type="button" onClick={() => void konumuAl()} disabled={locating} className={`${editorButtonClass} w-full`}>{locating ? "Konum alınıyor…" : "📍 Konumumu al (GPS)"}</button> : null}
                      {section.title === "Görseller" ? <div className="pt-2"><h3 className="mb-3 text-[13px] font-black text-lp-text">Galeri</h3><GalleryEditor inline slug={store.slug} items={galleryItems} onClose={() => { void onRefresh(); }} /></div> : null}
                    </div>
                  ) : null}
                </section>
              );
            })}
          </div>

          <div id="yasal-yayin-bolumu" className="scroll-mt-6 px-6 py-6">
            <div className={`rounded-[18px] border bg-lp-surface-soft p-4 ${legalAccepted ? "border-lp-primary" : "border-lp-border"}`}>
              <h2 className="flex items-center gap-2 text-[16px] font-black"><OnayIkonu boyut={20} className="text-lp-primary" /> Yasal Bilgilendirme ve Yayınlama Onayı</h2>
              <p className="mt-2 text-[12px] font-medium leading-5 text-lp-muted">Taslağınızı onay vermeden düzenleyebilirsiniz. Bu beyanlar yalnızca herkese açık yayınlama için gereklidir.</p>
              <label className="mt-4 flex cursor-pointer items-start gap-3 text-[12.5px] font-semibold leading-5 text-lp-text">
                <input type="checkbox" checked={legalAccepted} disabled={legalAccepted || publishing} onChange={() => { if (!legalAccepted) void acceptLegal(); }} className="mt-0.5 h-5 w-5 shrink-0 accent-[#147DFF]" />
                <span><Link href="/legal/privacy" target="_blank" className="font-bold text-lp-secondary underline">Aydınlatma Metni</Link>,{" "}<Link href="/legal/terms" target="_blank" className="font-bold text-lp-secondary underline">Kullanım Şartları</Link> ve{" "}<Link href="/legal/consent" target="_blank" className="font-bold text-lp-secondary underline">Açık Rıza Beyanı</Link>&apos;nı okudum, anladım ve kabul ediyorum.</span>
              </label>
            </div>
            <button type="button" onClick={publish} disabled={publishing || !legalAccepted} className="mt-4 min-h-[54px] w-full rounded-2xl bg-lp-primary px-5 text-[15px] font-black text-lp-on-primary disabled:bg-lp-surface-soft disabled:text-lp-muted disabled:opacity-70">{publishing ? "Yayına alınıyor…" : store.is_published ? "Değişiklikleri Kaydet & Yayına Al" : "Vitrinimi Yayına Al"}</button>
            <p className="mt-2 text-center text-[12px] font-semibold text-lp-muted">{store.is_published ? "Mevcut linkin korunur, Keşfet görünümün güncellenir." : "Linkin oluşur, Keşfet'te görünürsün."}</p>
          </div>
        </section>
      </div>

      {activeEditor === "gallery" ? <GalleryEditor slug={store.slug} items={galleryItems} onClose={() => { void closeStructuredEditor(); }} /> : null}
      {activeEditor === "faq" ? <FaqEditor slug={store.slug} items={faqItems} onClose={() => { void closeStructuredEditor(); }} /> : null}
      {activeEditor === "marketplace" ? <MarketplaceEditor slug={store.slug} links={marketplaceLinks} onClose={() => { void closeStructuredEditor(); }} /> : null}
      {activeEditor === "about" ? <AboutEditor slug={store.slug} mevcut={{ kicker: String(draft.about_kicker || ""), title: String(draft.about_title || ""), body: String(draft.corporate_bio || ""), imageUrl: String(draft.about_image_url || ""), imageCaption: String(draft.about_image_caption || ""), values: aboutValues }} onClose={() => { void closeStructuredEditor(); }} /> : null}
      {activeEditor === "campaign" ? <CampaignEditor slug={store.slug} mevcut={{ label: String(draft.featured_banner_label || ""), title: String(draft.featured_banner_title || ""), description: String(draft.featured_banner_description || ""), priceText: String(draft.featured_banner_price_text || ""), imageUrl: String(draft.featured_banner_image_url || "") }} onClose={() => { void closeStructuredEditor(); }} /> : null}
    </main>
  );
}
