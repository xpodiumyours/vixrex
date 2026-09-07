"use client";

import Link from "next/link";
import Image from "next/image";
import { useEffect, useMemo, useState } from "react";
import { OnayIkonu, StorefrontIkonu } from "@/components/site/icons";
import { useAppShell } from "@/components/app/AppShellContext";
import { VitrinPaylasimKarti } from "@/components/owner/VitrinPaylasimKarti";
import { FIELD_BY_KEY } from "@/lib/vitrinFieldSchema";
import { safeParseJson } from "@/lib/products";
import { gpsAdresiniCoz } from "@/lib/konumCozumleme";
import { turkeyProvinces, getDistrictsForProvince } from "@/lib/turkeyCities";
import { resolveVitrinProfile } from "@/lib/vitrinProfile";
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
  isCreationMode?: boolean;
  onCreate?: (draft: Draft) => Promise<void>;
}

type FieldSpec = {
  key: string;
  label: string;
  placeholder?: string;
  kind?: "text" | "textarea" | "url" | "email" | "tel" | "select";
  required?: boolean;
  options?: readonly string[];
};

type GpsOnerisi = {
  enlem: number;
  boylam: number;
  sapmaMetre: number;
  adres: string;
  il: string;
  ilce: string;
};

type HazirGorsel = {
  image_url: string;
  title?: string | null;
};

const SECTION_VISIBILITY = [
  { key: "categories", label: "Kategoriler" },
  { key: "products", label: "Ürünler" },
  { key: "about", label: "Hakkımızda" },
  { key: "gallery", label: "Galeri" },
  { key: "blog", label: "Blog" },
  { key: "faq", label: "Sık Sorulan Sorular" },
  { key: "contact", label: "İletişim & Konum" },
] as const;

const SECTIONS: Array<{ title: string; required?: boolean; fields: FieldSpec[] }> = [
  {
    title: "Kimlik",
    required: true,
    fields: [
      { key: "isletmeAdi", label: "İşletme / Vixrex Adı", placeholder: "Örn: Aymira Butik", required: true },
      { key: "isletmeTuru", label: "İşletme Türü", placeholder: "Örn: Kadın giyim / butik" },
      { key: "kisaTanitim", label: "Kısa Açıklama", placeholder: "Bugün vitrinde ne var? Kısa bir tanıtım yaz.", kind: "textarea" },
      { key: "heroRozet", label: "Kapak Rozeti", placeholder: "Örn: Atölye / Mağaza" },
      // F0 sözleşmesi: logo Next.js manuel panelinde düzenlenebilir kalır.
      { key: "logo", label: "Logo", placeholder: "Logo görsel bağlantısı", kind: "url" },
    ],
  },
  {
    title: "İletişim",
    required: true,
    fields: [
      { key: "whatsapp", label: "WhatsApp Numarası", placeholder: "05xx xxx xx xx", kind: "tel", required: true },
      { key: "telefon", label: "Telefon", placeholder: "05xx xxx xx xx (isteğe bağlı)", kind: "tel" },
      { key: "eposta", label: "E-posta", placeholder: "ornek@isletme.com", kind: "email" },
      { key: "instagram", label: "Instagram", placeholder: "@kullanici_adi veya profil linki" },
    ],
  },
  {
    title: "Konum ve saatler",
    required: true,
    fields: [
      { key: "il", label: "İl", required: true },
      { key: "ilce", label: "İlçe", required: true },
      { key: "adres", label: "Açık Adres (Mahalle, Cadde, Sokak, No)", placeholder: "Örn: Çatalmeşe Mah. 207. Sokak No: 12", kind: "textarea", required: true },
      // F0 sözleşmesi: ileri konum alanları Next.js manuel panelinde kalır.
      { key: "mahalle", label: "Mahalle", placeholder: "Örn: Caddebostan" },
      { key: "konumMetni", label: "Vitrin Konum Metni", placeholder: "Örn: Kadıköy, İstanbul" },
      { key: "haritaEtiketi", label: "Harita Kartı Etiketi", placeholder: "Örn: Çarşı içi" },
      { key: "calismaSaatleri", label: "Çalışma Saatleri", placeholder: "Örn: Pzt — Cmt 09:00 - 20:00" },
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
      { key: "galeriUstBaslik", label: "Galeri üst etiketi", placeholder: "Örn: Mağazadan kareler" },
      { key: "galeriBaslik", label: "Galeri başlığı", placeholder: "Örn: Atmosferi yakından tanı" },
      { key: "galeriAksiyonMetni", label: "Galeri Buton Metni", placeholder: "Örn: Hepsini gör" },
      { key: "galeriAksiyonLinki", label: "Galeri Buton Bağlantısı", kind: "url", placeholder: "https://" },
    ],
  },
  {
    title: "İçerik ve SEO",
    fields: [
      { key: "hakkindaMetin", label: "Hakkımızda Yazısı", kind: "textarea", placeholder: "İşletmenizin hikâyesini anlatın" },
      { key: "referansLinki", label: "Referanslar Bağlantısı", kind: "url", placeholder: "https://..." },
      { key: "kategoriBolumBaslik", label: "Kategori Bölümü Başlığı", placeholder: "Örn: Servis Alanlarımız" },
      { key: "urunBolumBaslik", label: "Ürün Bölümü Başlığı", placeholder: "Örn: Servis Fiyat Listesi" },
      { key: "blogUstBaslik", label: "Blog Üst Başlık", placeholder: "Örn: Teknik rehber" },
      { key: "blogBaslik", label: "Blog Bölüm Başlığı", placeholder: "Örn: Mağazadan Haberler" },
      { key: "sssUstBaslik", label: "SSS Üst Başlığı", placeholder: "Merak edilenler" },
      { key: "sssBaslik", label: "SSS Bölüm Başlığı", placeholder: "Sıkça sorulan sorular" },
      { key: "sssAciklama", label: "SSS Bölüm Açıklaması", kind: "textarea", placeholder: "Müşterilerinizin sık sorduğu konular" },
      { key: "haritaLinki", label: "Google Yorum Bağlantısı", kind: "url", placeholder: "https://search.google.com/local/writereview?placeid=..." },
    ],
  },
];

function columnFor(key: string): string {
  return FIELD_BY_KEY.get(key)?.kolon ?? key;
}

function valueFor(draft: Draft, key: string): string {
  const value = draft[columnFor(key)];
  return typeof value === "string" || typeof value === "number" ? String(value) : "";
}

function boolFor(draft: Draft, key: string, fallback: boolean): boolean {
  const value = draft[columnFor(key)];
  if (typeof value === "boolean") return value;
  if (value === "true") return true;
  if (value === "false") return false;
  return fallback;
}

function filled(value: unknown): boolean {
  if (Array.isArray(value)) return value.length > 0;
  if (value && typeof value === "object") return Object.keys(value as object).length > 0;
  return typeof value === "string" ? value.trim().length > 0 : Boolean(value);
}

function structuredFilled(value: unknown): boolean {
  if (Array.isArray(value)) return value.length > 0;
  if (typeof value === "string") {
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed.length > 0 : Boolean(parsed && typeof parsed === "object" && Object.keys(parsed).length);
    } catch {
      return value.trim().length > 0;
    }
  }
  return filled(value);
}

function parseSectionVisibility(value: unknown): Record<string, boolean> {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>).filter((entry): entry is [string, boolean] => typeof entry[1] === "boolean"),
    );
  }
  if (typeof value === "string" && value.trim()) {
    try {
      const parsed = JSON.parse(value) as unknown;
      if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
        return Object.fromEntries(
          Object.entries(parsed as Record<string, unknown>).filter((entry): entry is [string, boolean] => typeof entry[1] === "boolean"),
        );
      }
    } catch {
      return {};
    }
  }
  return {};
}

export function VitrinimEditor({ store, initialDraft, onRefresh, isCreationMode = false, onCreate }: Props) {
  const { refreshShellStatus } = useAppShell();
  const [draft, setDraft] = useState<Draft>({ name: store.name, ...initialDraft });
  const [openSection, setOpenSection] = useState(0);
  const [savingKey, setSavingKey] = useState<string | null>(null);
  const [publishing, setPublishing] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [locating, setLocating] = useState(false);
  const [gpsOnerisi, setGpsOnerisi] = useState<GpsOnerisi | null>(null);
  const [hazirGorseller, setHazirGorseller] = useState<HazirGorsel[]>([]);
  const [hazirYukleniyor, setHazirYukleniyor] = useState(false);
  const [structuredSaving, setStructuredSaving] = useState(false);
  const [legalAccepted, setLegalAccepted] = useState(() => Boolean(
    initialDraft.privacy_notice_version &&
    initialDraft.terms_version &&
    initialDraft.publication_consent_accepted
  ));
  const [message, setMessage] = useState("");

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
    const count = (keys: string[]) => keys.filter((key) => filled(draft[columnFor(key)])).length;
    const adresTamam = ["adres", "il", "ilce"].every((key) => filled(draft[columnFor(key)]));
    const aboutTamam = ["about_kicker", "about_title", "corporate_bio", "about_image_url"].some((key) => filled(draft[key])) || structuredFilled(draft.about_values);
    const urunTamam = (store.products?.length ?? 0) > 0 || structuredFilled(draft.offerings);
    const kampanyaTamam = ["featured_banner_label", "featured_banner_title", "featured_banner_description", "featured_banner_image_url"].some((key) => filled(draft[key]));
    const counts = [
      { done: count(["isletmeAdi", "kategori", "isletmeTuru", "kisaTanitim", "heroRozet"]), total: 5 },
      { done: count(["whatsapp", "telefon", "eposta", "instagram"]), total: 4 },
      { done: (adresTamam ? 1 : 0) + count(["konumMetni", "haritaEtiketi", "calismaSaatleri"]), total: 4 },
      { done: count(["kapakGorseli", "galeriUstBaslik", "galeriBaslik", "galeriAksiyonMetni", "galeriAksiyonLinki"]) + (structuredFilled(draft.gallery_items) ? 1 : 0), total: 6 },
      {
        done:
          (aboutTamam ? 1 : 0) +
          (urunTamam ? 1 : 0) +
          (kampanyaTamam ? 1 : 0) +
          (structuredFilled(draft.faq_items) ? 1 : 0) +
          count(["blogUstBaslik", "blogBaslik", "haritaLinki", "referansLinki", "kategoriBolumBaslik", "urunBolumBaslik"]) +
          (structuredFilled(draft.marketplace_links) ? 1 : 0) +
          1, // Flutter StoreData.status varsayılan "Açık"; boş bırakılmaz.
        total: 12,
      },
    ];
    const done = counts.reduce((sum, item) => sum + item.done, 0);
    const total = counts.reduce((sum, item) => sum + item.total, 0);
    return { counts, done, total, percent: total ? Math.round((done / total) * 100) : 0 };
  }, [draft, store.products]);

  const addressCompleted = ["adres", "il", "ilce"].every((key) => filled(valueFor(draft, key)));
  const missing = [
    !filled(valueFor(draft, "isletmeAdi")) ? "İşletme adı" : null,
    !filled(valueFor(draft, "kategori")) ? "Kategori" : null,
    !filled(valueFor(draft, "whatsapp")) ? "WhatsApp" : null,
    !addressCompleted ? "Adres" : null,
  ].filter((label): label is string => Boolean(label));

  const sectionVisibility = useMemo(() => parseSectionVisibility(draft.section_visibility), [draft.section_visibility]);
  const il = valueFor(draft, "il");
  const ilceler = getDistrictsForProvince(il);

  function updateLocal(key: string, value: unknown) {
    setDraft((current) => ({ ...current, [columnFor(key)]: value }));
  }

  function updateLocalColumn(column: string, value: unknown) {
    setDraft((current) => ({ ...current, [column]: value }));
  }

  async function saveValue(key: string, value: unknown, quiet = false) {
    if (isCreationMode) {
      if (!quiet) setMessage("Taslak güncellendi — yayınlayınca kaydedilecek.");
      return true;
    }
    setSavingKey(key);
    if (!quiet) setMessage("");
    try {
      const response = await fetch("/api/owner-draft", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug: store.slug,
          anahtar: key,
          deger: typeof value === "string" && value.trim() === "" ? null : value,
          clientId: null,
        }),
      });
      const body = await response.json();
      if (!response.ok) throw new Error(body?.hata ?? "Kaydedilemedi.");
      if (!quiet) setMessage("Değişiklik kaydedildi.");
      return true;
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Değişiklik kaydedilemedi.");
      return false;
    } finally {
      setSavingKey(null);
    }
  }

  async function save(key: string) {
    await saveValue(key, valueFor(draft, key));
  }

  async function saveStructured(column: string, value: Record<string, boolean>) {
    updateLocalColumn(column, value);
    if (isCreationMode) {
      setMessage("Taslak güncellendi — yayınlayınca kaydedilecek.");
      return true;
    }
    setStructuredSaving(true);
    setMessage("");
    try {
      const response = await fetch("/api/owner-structured-field", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: store.slug, kolon: column, deger: value }),
      });
      const body = await response.json();
      if (!response.ok) throw new Error(body?.hata ?? "Bölüm görünürlüğü kaydedilemedi.");
      setMessage("Bölüm görünürlüğü kaydedildi.");
      return true;
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Bölüm görünürlüğü kaydedilemedi.");
      return false;
    } finally {
      setStructuredSaving(false);
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
      setMessage("Dosya yükleme vitrin oluşturulduktan sonra kullanılabilir. Hazır görsel seçebilirsin.");
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
      const saved = await saveValue(anahtar, uploadBody.url, true);
      if (!saved) return;
      setMessage(`${FIELD_BY_KEY.get(anahtar)?.etiket ?? "Görsel"} kaydedildi.`);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Görsel yüklenemedi.");
    } finally {
      setUploading(false);
    }
  }

  async function hazirKapaklariAc() {
    if (hazirGorseller.length > 0) {
      setHazirGorseller([]);
      return;
    }
    setHazirYukleniyor(true);
    setMessage("");
    try {
      const profil = resolveVitrinProfile(
        valueFor(draft, "kategori") || null,
        valueFor(draft, "isletmeTuru") || null,
      );
      const response = await fetch(`/api/category-images?category=${encodeURIComponent(profil.id)}`);
      const body = await response.json();
      const images = (body?.images?.cover ?? []) as HazirGorsel[];
      if (!response.ok || images.length === 0) {
        setMessage(`${profil.label} kategorisi için hazır kapak bulunamadı. Kendi fotoğrafını yükleyebilirsin.`);
        return;
      }
      setHazirGorseller(images);
    } catch {
      setMessage("Hazır görseller getirilemedi. Tekrar dene.");
    } finally {
      setHazirYukleniyor(false);
    }
  }

  async function hazirKapakSec(url: string) {
    updateLocal("kapakGorseli", url);
    setHazirGorseller([]);
    const saved = await saveValue("kapakGorseli", url, true);
    if (saved) setMessage("Kapak Görseli güncellendi.");
  }

  async function konumuAl() {
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      setMessage("Tarayıcı konum desteği vermiyor.");
      return;
    }
    setLocating(true);
    setGpsOnerisi(null);
    setMessage("Konum aranıyor...");
    try {
      const pos = await new Promise<GeolocationPosition>((resolve, reject) =>
        navigator.geolocation.getCurrentPosition(resolve, reject, { enableHighAccuracy: true, timeout: 10000 }),
      );

      let adres = "";
      let provinceName = "";
      let districtName = "";
      try {
        const cozum = await gpsAdresiniCoz(pos.coords.latitude, pos.coords.longitude);
        adres = cozum.address;
        provinceName = cozum.provinceName;
        districtName = cozum.districtName;
      } catch {
        // Flutter ile aynı güvenlik: adres çözülemese bile koordinat öneri olarak gösterilir,
        // kullanıcı onaylamadan hiçbir alana yazılmaz.
      }

      setGpsOnerisi({
        enlem: pos.coords.latitude,
        boylam: pos.coords.longitude,
        sapmaMetre: pos.coords.accuracy,
        adres,
        il: provinceName,
        ilce: districtName,
      });
      setMessage("");
    } catch (error) {
      const msg = error instanceof GeolocationPositionError
        ? error.message
        : "Konum alınamadı. İzin verin ve tekrar deneyin.";
      setMessage(msg);
    } finally {
      setLocating(false);
    }
  }

  async function gpsOnerisiniKabulEt() {
    const suggestion = gpsOnerisi;
    if (!suggestion) return;

    const values: Array<[string, string]> = [
      ["enlem", suggestion.enlem.toFixed(6)],
      ["boylam", suggestion.boylam.toFixed(6)],
    ];
    if (suggestion.il) values.push(["il", suggestion.il]);
    if (suggestion.ilce) values.push(["ilce", suggestion.ilce]);
    if (suggestion.adres) values.push(["adres", suggestion.adres]);

    setDraft((current) => {
      const next = { ...current };
      for (const [key, value] of values) next[columnFor(key)] = value;
      return next;
    });

    if (!isCreationMode) {
      for (const [key, value] of values) {
        const ok = await saveValue(key, value, true);
        if (!ok) return;
      }
    }

    setGpsOnerisi(null);
    setMessage("Konum kaydedildi.");
  }

  function gpsOnerisiniReddet() {
    setGpsOnerisi(null);
    setMessage("Konum kullanılmadı. İl, ilçe ve adresi elle yaz.");
  }

  function ilDegistir(value: string) {
    const districtOptions = getDistrictsForProvince(value);
    const currentDistrict = valueFor(draft, "ilce");
    updateLocal("il", value);
    if (currentDistrict && !districtOptions.includes(currentDistrict)) updateLocal("ilce", "");
    setMessage("İl seçildi — ilçe seçerek kaydet.");
  }

  async function ilceDegistir(value: string) {
    const currentProvince = valueFor(draft, "il");
    updateLocal("ilce", value);
    if (currentProvince) {
      const provinceSaved = await saveValue("il", currentProvince, true);
      if (!provinceSaved) return;
    }
    const districtSaved = await saveValue("ilce", value, true);
    if (districtSaved) setMessage("Konum bilgisi kaydedildi.");
  }

  async function boolDegistir(key: "yolTarifiGoster" | "puanGoster", value: boolean) {
    updateLocal(key, value);
    const ok = await saveValue(key, value, true);
    if (ok) setMessage("Değişiklik kaydedildi.");
  }

  async function bolumGorunurluguDegistir(key: typeof SECTION_VISIBILITY[number]["key"]) {
    const mevcut = { ...sectionVisibility };
    if (mevcut[key] !== false) mevcut[key] = false;
    else delete mevcut[key];
    await saveStructured("section_visibility", mevcut);
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
  const switchClass = (active: boolean) =>
    `relative inline-flex h-6 w-11 shrink-0 items-center rounded-full transition ${active ? "bg-lp-primary" : "bg-lp-surface-soft"}`;

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
          {store.is_published
            ? "Düzenledikten sonra kaydet, linkin ve QR kodun güncellenir."
            : "Ad, WhatsApp ve konumunu gir — vitrin hazır. Diğer detayları sonra ekleyebilirsin."}
        </p>

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
            <div className="mt-3 h-1.5 overflow-hidden rounded-full bg-lp-surface-soft">
              <div className="h-full rounded-full bg-lp-primary transition-all" style={{ width: `${progress.percent}%` }} />
            </div>
            <p className="mt-3 text-[12px] font-medium text-lp-muted">
              {missing.length
                ? `Yayına çıkmak için ${missing.join(", ")} ve Yasal onay alanları kaldı.`
                : "Temel bilgiler hazır. Yasal onaydan sonra yayınlayabilirsin."}
            </p>
          </div>

          {message ? (
            <p className="mx-6 mt-4 rounded-xl border border-lp-border bg-lp-bg-light px-4 py-3 text-[12px] text-lp-text" role="status">
              {message}
            </p>
          ) : null}

          <div className="grid min-[901px]:grid-cols-2">
            {SECTIONS.map((section, index) => {
              const count = progress.counts[index];
              const isOpen = openSection === index;
              return (
                <section key={section.title} className="border-b border-lp-border min-[901px]:[&:nth-child(odd)]:border-r">
                  <button
                    type="button"
                    onClick={() => setOpenSection(isOpen ? -1 : index)}
                    className="flex min-h-[76px] w-full items-center gap-3 px-6 text-left hover:bg-lp-surface-soft/45"
                    aria-expanded={isOpen}
                  >
                    <span className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full border text-[13px] font-bold ${count.done === count.total ? "border-emerald-500 bg-emerald-500/15 text-emerald-300" : "border-lp-border bg-lp-surface-soft text-lp-secondary"}`}>
                      {index + 1}
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block text-[16px] font-black">{section.title}</span>
                      <span className="mt-0.5 block text-[12px] font-semibold text-lp-muted">
                        {count.done} / {count.total} alan dolu{section.required ? " · zorunlu" : ""}
                      </span>
                    </span>
                    <span className="text-[12px] font-bold text-lp-muted">{isOpen ? "Kapat" : "Aç"}</span>
                  </button>

                  {isOpen ? (
                    <div className="space-y-4 px-6 pb-6">
                      {section.fields.map((field) => {
                        const id = `vitrin-${field.key}`;
                        const value = valueFor(draft, field.key);
                        const common = "min-h-12 w-full rounded-xl border border-lp-border bg-lp-bg-light px-4 text-[14px] font-semibold text-lp-text outline-none transition placeholder:text-lp-muted/70 focus:border-lp-secondary focus:ring-2 focus:ring-lp-primary/25";

                        if (field.key === "il") {
                          return (
                            <div key={field.key}>
                              <label htmlFor={id} className="mb-2 block text-[13px] font-bold text-lp-text-alt">
                                İl <span className="text-lp-primary">*</span>
                              </label>
                              <select id={id} value={value} onChange={(event) => ilDegistir(event.target.value)} className={common}>
                                <option value="">İl seçiniz</option>
                                {turkeyProvinces.map((province) => <option key={province.code} value={province.name}>{province.name}</option>)}
                              </select>
                            </div>
                          );
                        }

                        if (field.key === "ilce") {
                          return (
                            <div key={field.key}>
                              <label htmlFor={id} className="mb-2 block text-[13px] font-bold text-lp-text-alt">
                                İlçe <span className="text-lp-primary">*</span>
                              </label>
                              <select
                                id={id}
                                value={value}
                                disabled={!il}
                                onChange={(event) => { void ilceDegistir(event.target.value); }}
                                className={`${common} disabled:cursor-not-allowed disabled:opacity-60`}
                              >
                                <option value="">{il ? "İlçe seçiniz" : "Önce il seçiniz"}</option>
                                {ilceler.map((district) => <option key={district} value={district}>{district}</option>)}
                              </select>
                            </div>
                          );
                        }

                        return (
                          <div key={field.key}>
                            <label htmlFor={id} className="mb-2 block text-[13px] font-bold text-lp-text-alt">
                              {field.label}{field.required ? <span className="text-lp-primary"> *</span> : null}
                            </label>
                            {field.key === "kapakGorseli" || field.key === "logo" ? (
                              <div className="space-y-3">
                                {value ? (
                                  <div className="relative aspect-[16/7] w-full overflow-hidden rounded-2xl border border-lp-border">
                                    <Image src={value} alt={`${field.label} önizlemesi`} fill sizes="(max-width: 1024px) 100vw, 540px" className="object-cover" />
                                  </div>
                                ) : null}
                                <div className={`grid gap-2 ${field.key === "kapakGorseli" ? "sm:grid-cols-3" : ""}`}>
                                  <label htmlFor={id} className="flex min-h-12 cursor-pointer items-center justify-center rounded-xl border border-lp-border bg-lp-bg-light px-3 text-center text-[13px] font-black text-lp-secondary hover:border-lp-primary">
                                    {uploading ? "Yükleniyor…" : "Dosya yükle"}
                                  </label>
                                  {field.key === "kapakGorseli" ? (
                                    <>
                                      <label htmlFor={`${id}-camera`} className="flex min-h-12 cursor-pointer items-center justify-center rounded-xl border border-lp-border bg-lp-bg-light px-3 text-center text-[13px] font-black text-lp-secondary hover:border-lp-primary">
                                        Kamera
                                      </label>
                                      <button type="button" onClick={() => { void hazirKapaklariAc(); }} disabled={hazirYukleniyor} className={editorButtonClass}>
                                        {hazirYukleniyor ? "Getiriliyor…" : "Hazır görseller"}
                                      </button>
                                    </>
                                  ) : null}
                                </div>
                                <input id={id} type="file" accept="image/jpeg,image/png,image/webp" disabled={uploading} onChange={(event) => { const file = event.target.files?.[0]; if (file) void uploadGorsel(file, field.key); }} className="sr-only" />
                                {field.key === "kapakGorseli" ? (
                                  <input id={`${id}-camera`} type="file" accept="image/*" capture="environment" disabled={uploading} onChange={(event) => { const file = event.target.files?.[0]; if (file) void uploadGorsel(file, field.key); }} className="sr-only" />
                                ) : null}
                                {field.key === "kapakGorseli" && hazirGorseller.length > 0 ? (
                                  <div className="grid max-h-56 grid-cols-3 gap-2 overflow-y-auto rounded-xl border border-lp-border bg-lp-bg-light p-2">
                                    {hazirGorseller.map((gorsel) => (
                                      <button key={gorsel.image_url} type="button" onClick={() => { void hazirKapakSec(gorsel.image_url); }} className="relative aspect-square overflow-hidden rounded-lg border border-lp-border hover:border-lp-primary" title={gorsel.title ?? "Hazır görsel"}>
                                        <Image src={gorsel.image_url} alt={gorsel.title ?? "Hazır görsel"} fill sizes="160px" className="object-cover" />
                                      </button>
                                    ))}
                                  </div>
                                ) : null}
                              </div>
                            ) : field.kind === "textarea" ? (
                              <textarea id={id} value={value} placeholder={field.placeholder} onChange={(event) => updateLocal(field.key, event.target.value)} onBlur={() => { void save(field.key); }} className={`${common} min-h-24 resize-y py-3`} />
                            ) : field.kind === "select" ? (
                              <select id={id} value={value} onChange={(event) => updateLocal(field.key, event.target.value)} onBlur={() => { void save(field.key); }} className={common}>
                                <option value="">Seçiniz</option>
                                {field.options?.map((option) => <option key={option} value={option}>{option}</option>)}
                              </select>
                            ) : (
                              <input id={id} type={field.kind ?? "text"} value={value} placeholder={field.placeholder} onChange={(event) => updateLocal(field.key, event.target.value)} onBlur={() => { void save(field.key); }} className={common} />
                            )}
                            {savingKey === field.key ? <span className="mt-1 block text-right text-[11px] font-semibold text-lp-secondary">Kaydediliyor…</span> : null}
                          </div>
                        );
                      })}

                      {section.title === "Konum ve saatler" ? (
                        <div className="space-y-3">
                          <button type="button" onClick={() => { void konumuAl(); }} disabled={locating} className={`${editorButtonClass} w-full`}>
                            {locating ? "GPS Taranıyor..." : "📍 GPS ile Konumumu Al"}
                          </button>

                          {gpsOnerisi ? (
                            <div className="rounded-xl border border-lp-primary/40 bg-lp-bg-light p-3">
                              <p className="text-[12.5px] font-extrabold text-lp-text">Konumunu buldum. Burası mı?</p>
                              <p className="mt-1.5 text-[13px] font-semibold leading-5 text-lp-secondary">
                                {gpsOnerisi.adres || "Adres çözülemedi"}
                              </p>
                              <p className="mt-1 text-[11px] text-lp-muted">yaklaşık {Math.round(gpsOnerisi.sapmaMetre)} m sapma</p>
                              <div className="mt-3 grid grid-cols-2 gap-2">
                                <button type="button" onClick={() => { void gpsOnerisiniKabulEt(); }} className="min-h-10 rounded-xl bg-lp-primary px-3 text-[12px] font-black text-lp-on-primary">
                                  Evet, burası
                                </button>
                                <button type="button" onClick={gpsOnerisiniReddet} className="min-h-10 rounded-xl border border-lp-border px-3 text-[12px] font-black text-lp-muted">
                                  Hayır, elle yazayım
                                </button>
                              </div>
                            </div>
                          ) : null}

                          <div className="flex items-center gap-3 rounded-xl border border-lp-border bg-lp-bg-light p-3">
                            <div className="min-w-0 flex-1">
                              <p className="text-[13px] font-bold text-lp-text">Yol tarifi butonu göster</p>
                              <p className="mt-0.5 text-[11px] leading-4 text-lp-muted">Adres veya GPS varsa vitrinde yol tarifi linki çıkar.</p>
                            </div>
                            <button type="button" role="switch" aria-checked={boolFor(draft, "yolTarifiGoster", true)} onClick={() => { void boolDegistir("yolTarifiGoster", !boolFor(draft, "yolTarifiGoster", true)); }} className={switchClass(boolFor(draft, "yolTarifiGoster", true))}>
                              <span className={`h-4 w-4 rounded-full bg-white shadow transition-transform ${boolFor(draft, "yolTarifiGoster", true) ? "translate-x-6" : "translate-x-1"}`} />
                            </button>
                          </div>
                        </div>
                      ) : null}

                      {section.title === "Görseller" ? (
                        <div className="pt-2">
                          <h3 className="mb-3 text-[13px] font-black text-lp-text">Galeri</h3>
                          <GalleryEditor inline slug={store.slug} items={galleryItems} onClose={() => { void onRefresh(); }} />
                        </div>
                      ) : null}

                      {section.title === "İçerik ve SEO" ? (
                        <div className="space-y-6 pt-2">
                          <div className="space-y-4">
                            <h3 className="text-[13px] font-black text-lp-text">Hakkımızda</h3>
                            <AboutEditor inline slug={store.slug} mevcut={{ kicker: String(draft.about_kicker || ""), title: String(draft.about_title || ""), body: String(draft.corporate_bio || ""), imageUrl: String(draft.about_image_url || ""), imageCaption: String(draft.about_image_caption || ""), values: aboutValues }} onClose={() => { void onRefresh(); }} />
                          </div>

                          <p className="mb-3 text-[12px] font-bold text-lp-muted">Ürünler ve kategoriler</p>
                          <OwnerProductManager storeSlug={store.slug} products={store.products ?? []} categories={store.product_categories ?? []} onRefresh={onRefresh} />

                          <div className="space-y-4">
                            <h3 className="text-[13px] font-black text-lp-text">Öne çıkan kampanya</h3>
                            <CampaignEditor inline slug={store.slug} mevcut={{ label: String(draft.featured_banner_label || ""), title: String(draft.featured_banner_title || ""), description: String(draft.featured_banner_description || ""), priceText: String(draft.featured_banner_price_text || ""), imageUrl: String(draft.featured_banner_image_url || "") }} onClose={() => { void onRefresh(); }} />
                          </div>

                          <div className="space-y-4">
                            <h3 className="text-[13px] font-black text-lp-text">Sık sorulanlar</h3>
                            <FaqEditor inline slug={store.slug} items={faqItems} onClose={() => { void onRefresh(); }} />
                          </div>

                          <Link href={`/v/${store.slug}/blog-yonetim`} className={`${editorButtonClass} flex items-center justify-center`}>Blog yönetimi</Link>

                          <div className="flex items-center gap-3 rounded-xl border border-lp-border bg-lp-bg-light p-3">
                            <div className="min-w-0 flex-1">
                              <p className="text-[13px] font-bold text-lp-text">Vitrinde puan bandı göster</p>
                              <p className="mt-0.5 text-[11px] leading-4 text-lp-muted">Gerçek puanın yoksa kapalı kalsın; örnek puan görünmesin.</p>
                            </div>
                            <button type="button" role="switch" aria-checked={boolFor(draft, "puanGoster", false)} onClick={() => { void boolDegistir("puanGoster", !boolFor(draft, "puanGoster", false)); }} className={switchClass(boolFor(draft, "puanGoster", false))}>
                              <span className={`h-4 w-4 rounded-full bg-white shadow transition-transform ${boolFor(draft, "puanGoster", false) ? "translate-x-6" : "translate-x-1"}`} />
                            </button>
                          </div>

                          <div className="space-y-4">
                            <h3 className="text-[13px] font-black text-lp-text">Pazar yeri bağlantıları</h3>
                            <MarketplaceEditor inline slug={store.slug} links={marketplaceLinks} onClose={() => { void onRefresh(); }} />
                          </div>

                          <div className="rounded-xl border border-lp-border bg-lp-bg-light p-3">
                            <h3 className="text-[13px] font-black text-lp-text">Bölüm görünürlüğü</h3>
                            <p className="mt-1 text-[11px] leading-4 text-lp-muted">Kapattığın bölüm vitrinde görünmez. Açık bölüm, içinde veri varsa otomatik görünür.</p>
                            <div className="mt-3 space-y-2">
                              {SECTION_VISIBILITY.map((item) => {
                                const visible = sectionVisibility[item.key] !== false;
                                return (
                                  <div key={item.key} className="flex items-center gap-3 rounded-lg px-1 py-1.5">
                                    <span className="min-w-0 flex-1 text-[12.5px] font-semibold text-lp-text-alt">{item.label}</span>
                                    <button type="button" role="switch" aria-checked={visible} disabled={structuredSaving} onClick={() => { void bolumGorunurluguDegistir(item.key); }} className={`${switchClass(visible)} disabled:opacity-50`}>
                                      <span className={`h-4 w-4 rounded-full bg-white shadow transition-transform ${visible ? "translate-x-6" : "translate-x-1"}`} />
                                    </button>
                                  </div>
                                );
                              })}
                            </div>
                          </div>
                        </div>
                      ) : null}
                    </div>
                  ) : null}
                </section>
              );
            })}
          </div>

          <div id="yasal-yayin-bolumu" className="scroll-mt-6 px-6 py-6">
            <div className={`rounded-[18px] border bg-lp-surface-soft p-4 ${legalAccepted ? "border-lp-primary" : "border-lp-border"}`}>
              <h2 className="flex items-center gap-2 text-[16px] font-black">
                <OnayIkonu boyut={20} className="text-lp-primary" /> Yasal Bilgilendirme ve Yayınlama Onayı
              </h2>
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
            <button type="button" onClick={() => { void publish(); }} disabled={publishing || !legalAccepted} className="mt-4 min-h-[54px] w-full rounded-2xl bg-lp-primary px-5 text-[15px] font-black text-lp-on-primary disabled:bg-lp-surface-soft disabled:text-lp-muted disabled:opacity-70">
              {publishing ? "Yayına alınıyor…" : store.is_published ? "Değişiklikleri Kaydet & Yayına Al" : "Vitrinimi Yayına Al"}
            </button>
            <p className="mt-2 text-center text-[12px] font-semibold text-lp-muted">
              {store.is_published ? "Mevcut linkin korunur, Keşfet görünümün güncellenir." : "Linkin oluşur, Keşfet'te görünürsün."}
            </p>
          </div>
        </section>
      </div>
    </main>
  );
}
