import Image from "next/image";
import Link from "next/link";
import { Suspense, type CSSProperties, type ReactNode } from "react";
import type { VitrinCategoryProfile, PrimaryActionId } from "@/lib/vitrinProfile";
import { getVitrinCopy, normalizeAddressDisplay } from "@/lib/vitrinCopy";
import {
  GlobeIcon,
  GoogleIcon,
  InstagramIcon,
  MapPinIcon,
  WhatsAppIcon,
} from "@/lib/vitrinBrandIcons";
import { normalizeExternalUrl } from "@/lib/products";

export interface VitrinGalleryItem {
  id?: string;
  imageUrl: string;
  title?: string;
}

export interface VitrinMarketplaceLink {
  id?: string;
  platform: string;
  url: string;
  subtitle?: string;
}

export interface VitrinArticleTeaser {
  id: string;
  slug: string;
  title: string;
  summary?: string | null;
  content: string;
}

export interface VitrinCollection {
  name: string;
  count: number;
}

export interface VitrinProfileViewProps {
  storeName: string;
  storeSlug: string;
  kategori: string | null;
  businessType: string | null;
  status: string | null;
  isClosed?: boolean;
  logoUrl: string | null;
  heroImage: string;
  description: string;
  corporateBio: string | null;
  address: string | null;
  workingHoursToday: string | null;
  workingHoursWeek: Array<{ day: string; hours: string; isToday: boolean }>;
  googleBusinessLink: string | null;
  publicUrl: string;
  whatsappUrl: string | null;
  instagramUrl: string | null;
  websiteUrl: string | null;
  mapsUrl: string | null;
  referencesUrl: string | null;
  isBookingEnabled: boolean;
  profile: VitrinCategoryProfile;
  collections: VitrinCollection[];
  productCount: number;
  galleryItems: VitrinGalleryItem[];
  marketplaceLinks: VitrinMarketplaceLink[];
  articles: VitrinArticleTeaser[];
  catalog: ReactNode;
}

function isHttpUrl(href: string) {
  return /^https?:\/\//i.test(href);
}

function ActionButton({
  href,
  variant,
  children,
  icon,
  ariaLabel,
  className = "",
}: {
  href: string;
  variant: "wa" | "map" | "book" | "ghost";
  children: ReactNode;
  icon?: ReactNode;
  ariaLabel?: string;
  className?: string;
}) {
  const base =
    "v-action-btn inline-flex items-center justify-center rounded-full font-extrabold transition hover:opacity-95";
  const styles = {
    wa: "bg-[#25D366] text-[#04140a] shadow-lg shadow-emerald-950/30",
    map: "border border-white/20 bg-white/10 text-white backdrop-blur-sm",
    book: "border border-[#E8A87C]/55 text-[#E8A87C]",
    ghost: "border border-white/15 bg-white/5 text-white",
  } as const;
  const classes = `${base} ${styles[variant]} ${className}`.trim();
  const content = (
    <>
      {icon}
      <span className="truncate">{children}</span>
    </>
  );

  if (isHttpUrl(href)) {
    return (
      <a
        href={href}
        target="_blank"
        rel="noopener noreferrer"
        aria-label={ariaLabel}
        className={classes}
      >
        {content}
      </a>
    );
  }

  return (
    <Link href={href} aria-label={ariaLabel} className={classes}>
      {content}
    </Link>
  );
}

function SocialIconLink({
  href,
  label,
  children,
}: {
  href: string;
  label: string;
  children: ReactNode;
}) {
  const className =
    "grid h-11 w-11 place-items-center rounded-full border border-white/10 bg-white/5 text-white/80 transition hover:border-white/25 hover:bg-white/10 hover:text-white";

  if (isHttpUrl(href)) {
    return (
      <a
        href={href}
        target="_blank"
        rel="noopener noreferrer"
        title={label}
        aria-label={label}
        className={className}
      >
        {children}
      </a>
    );
  }

  return (
    <Link href={href} title={label} aria-label={label} className={className}>
      {children}
    </Link>
  );
}

function buildVcardHref(name: string, phoneDigits: string | null, address: string | null) {
  const lines = [
    "BEGIN:VCARD",
    "VERSION:3.0",
    `FN:${name}`,
    phoneDigits ? `TEL;TYPE=CELL:+${phoneDigits}` : "",
    address ? `ADR;TYPE=WORK:;;${address};;;;` : "",
    "END:VCARD",
  ].filter(Boolean);
  return `data:text/vcard;charset=utf-8,${encodeURIComponent(lines.join("\n"))}`;
}

export default function VitrinProfileView({
  storeName,
  storeSlug,
  status,
  isClosed: isClosedProp,
  logoUrl,
  heroImage,
  description,
  corporateBio,
  address,
  workingHoursToday,
  workingHoursWeek,
  googleBusinessLink,
  publicUrl,
  whatsappUrl,
  instagramUrl,
  websiteUrl,
  mapsUrl,
  referencesUrl,
  isBookingEnabled,
  profile,
  collections,
  productCount,
  galleryItems,
  marketplaceLinks,
  articles,
  catalog,
}: VitrinProfileViewProps) {
  const isClosed =
    typeof isClosedProp === "boolean"
      ? isClosedProp
      : Boolean(status?.startsWith("Kapalı"));
  const copy = getVitrinCopy(profile.id);
  const displayAddress = normalizeAddressDisplay(address);
  const phoneFromWa = whatsappUrl?.match(/wa\.me\/(\d+)/)?.[1] ?? null;
  const vcardHref = buildVcardHref(storeName, phoneFromWa, displayAddress);

  const actionUrls: Record<PrimaryActionId, string | null> = {
    whatsapp: whatsappUrl,
    maps: mapsUrl,
    booking: isBookingEnabled ? `/v/${storeSlug}/randevu` : null,
    website: websiteUrl,
  };

  const actionLabels: Record<PrimaryActionId, string> = {
    whatsapp: `WhatsApp · ${copy.whatsappButton}`,
    maps: "Yol tarifi",
    booking: "Randevu al",
    website: "Web sitesi",
  };

  const actionIcons: Record<PrimaryActionId, ReactNode> = {
    whatsapp: <WhatsAppIcon className="v-action-icon" size={16} />,
    maps: <MapPinIcon className="v-action-icon" size={16} />,
    booking: null,
    website: <GlobeIcon className="v-action-icon" size={16} />,
  };

  const actionVariants: Record<PrimaryActionId, "wa" | "map" | "book" | "ghost"> = {
    whatsapp: "wa",
    maps: "map",
    booking: "book",
    website: "ghost",
  };

  const primary = profile.primaryActions
    .map((id) => ({ id, href: actionUrls[id] }))
    .filter((a): a is { id: PrimaryActionId; href: string } => Boolean(a.href))
    .slice(0, 3);

  // WhatsApp yoksa ama maps var — yine de doldur
  if (primary.length === 0 && mapsUrl) {
    primary.push({ id: "maps", href: mapsUrl });
  }

  /** Mobil: WA tam satır + ikinciller 2 kolon; masaüstü: flex tek satır */
  type HeroAction = {
    key: string;
    href: string;
    variant: "wa" | "map" | "book" | "ghost";
    label: string;
    icon: ReactNode;
  };

  const mappedPrimary: HeroAction[] = primary.map((a) => ({
    key: a.id,
    href: a.href,
    variant: actionVariants[a.id],
    label: actionLabels[a.id],
    icon: actionIcons[a.id],
  }));

  const whatsappAction = mappedPrimary.find((a) => a.key === "whatsapp") ?? null;
  const secondaryActions: HeroAction[] = [
    ...mappedPrimary.filter((a) => a.key !== "whatsapp"),
    ...(instagramUrl
      ? [
          {
            key: "instagram",
            href: instagramUrl,
            variant: "ghost" as const,
            label: "Instagram",
            icon: <InstagramIcon className="v-action-icon" size={16} />,
          },
        ]
      : []),
  ];

  /** Tek anlamlı chip: resolved kategori etiketi */
  const categoryChip = profile.label;

  return (
    <div className="vitrin-shell min-h-screen bg-[#0c0d10] text-[#f4f1ea]">
      {/* HERO */}
      <header
        className="relative isolate flex flex-col justify-end overflow-hidden"
        style={{ minHeight: "var(--v-hero-min-h)" }}
      >
        {heroImage ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={heroImage}
            alt=""
            className="absolute inset-0 -z-20 h-full w-full object-cover"
            loading="eager"
          />
        ) : (
          <div className="absolute inset-0 -z-20 bg-[#1c1f27]" />
        )}
        <div className="absolute inset-0 -z-10 bg-[linear-gradient(180deg,rgba(12,13,16,0.25)_0%,rgba(12,13,16,0.55)_40%,rgba(12,13,16,0.96)_100%)]" />

        <div
          className="absolute left-0 right-0 top-0 z-10 mx-auto flex w-full max-w-[1080px] items-center justify-between pt-3"
          style={{ paddingLeft: "var(--v-hero-pad-x)", paddingRight: "var(--v-hero-pad-x)" }}
        >
          <Link href="/" className="text-sm font-extrabold tracking-tight text-white sm:text-[15px]">
            Vix<span className="text-[#E8A87C]">rex</span>
          </Link>
          <div className="flex items-center gap-2">
            {articles.length > 0 && (
              <Link
                href={`/v/${storeSlug}/yazilar`}
                className="rounded-full border border-white/15 bg-white/10 px-2.5 py-1 text-[10px] font-extrabold text-white/90 sm:px-3 sm:py-1.5 sm:text-[11px]"
              >
                Yazılar
              </Link>
            )}
            <span
              className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-[10px] font-extrabold sm:px-3 sm:py-1.5 sm:text-[11px] ${
                isClosed
                  ? "border-rose-400/35 bg-rose-500/15 text-rose-200"
                  : "border-emerald-400/35 bg-emerald-400/14 text-emerald-200"
              }`}
            >
              <span
                className={`h-1.5 w-1.5 rounded-full ${isClosed ? "bg-rose-300" : "bg-[#25D366]"}`}
              />
              {status || (isClosed ? "Kapalı" : "Açık")}
            </span>
          </div>
        </div>

        <div
          className="relative z-10 mx-auto w-full max-w-[1080px]"
          style={{
            paddingLeft: "var(--v-hero-pad-x)",
            paddingRight: "var(--v-hero-pad-x)",
            paddingTop: "var(--v-hero-pad-top)",
            paddingBottom: "var(--v-hero-pad-bottom)",
          }}
        >
          <div className="flex items-end gap-3 sm:gap-4">
            {logoUrl ? (
              <Image
                src={logoUrl}
                alt={`${storeName} logo`}
                width={104}
                height={104}
                className="shrink-0 rounded-full border-2 border-white/55 bg-white object-contain shadow-2xl"
                style={{ width: "var(--v-avatar)", height: "var(--v-avatar)" }}
              />
            ) : (
              <div
                className="flex shrink-0 items-center justify-center rounded-full border-2 border-white/55 bg-[#15171c] text-2xl font-black text-[#E8A87C] shadow-2xl sm:text-3xl"
                style={{ width: "var(--v-avatar)", height: "var(--v-avatar)" }}
              >
                {storeName ? storeName.substring(0, 1).toUpperCase() : "V"}
              </div>
            )}
            <div className="min-w-0 flex-1">
              <div className="mb-1.5 flex flex-wrap gap-1.5 sm:mb-2">
                <span className="rounded-full border border-[#E8A87C]/30 bg-[#E8A87C]/15 px-2 py-0.5 text-[10px] font-bold text-[#F0D0B4] sm:px-2.5 sm:py-1 sm:text-[11px]">
                  {categoryChip}
                </span>
              </div>
              <h1
                className="font-extrabold leading-[1.05] tracking-[-0.03em] text-white"
                style={{ fontSize: "var(--v-title-size)" }}
              >
                {storeName}
              </h1>
            </div>
          </div>

          <p
            className="mt-3 max-w-[40ch] font-medium leading-relaxed text-white/82 sm:mt-4"
            style={{ fontSize: "var(--v-bio-size)" }}
          >
            {description}
          </p>

          {(whatsappAction || secondaryActions.length > 0) && (
            <div
              className="mt-3.5 flex flex-col sm:mt-5 sm:flex-row sm:flex-wrap sm:items-center"
              style={{ gap: "var(--v-btn-gap)" }}
            >
              {whatsappAction && (
                <ActionButton
                  href={whatsappAction.href}
                  variant={whatsappAction.variant}
                  icon={whatsappAction.icon}
                  ariaLabel={whatsappAction.label}
                  className="w-full sm:w-auto sm:max-w-none"
                >
                  {whatsappAction.label}
                </ActionButton>
              )}
              {secondaryActions.length > 0 && (
                <div
                  className={
                    secondaryActions.length === 1
                      ? "grid grid-cols-1 sm:contents"
                      : "grid grid-cols-2 sm:contents"
                  }
                  style={{ gap: "var(--v-btn-gap)" }}
                >
                  {secondaryActions.map((a) => (
                    <ActionButton
                      key={a.key}
                      href={a.href}
                      variant={a.variant}
                      icon={a.icon}
                      ariaLabel={a.label}
                      className="w-full min-w-0 sm:w-auto"
                    >
                      {a.label}
                    </ActionButton>
                  ))}
                </div>
              )}
            </div>
          )}

          {(websiteUrl && !primary.some((p) => p.id === "website")) ||
          googleBusinessLink ||
          articles.length > 0 ||
          referencesUrl ? (
            <div className="mt-3 flex flex-wrap gap-2">
              {websiteUrl && !primary.some((p) => p.id === "website") && (
                <SocialIconLink href={websiteUrl} label="Web sitesi">
                  <GlobeIcon size={18} />
                </SocialIconLink>
              )}
              {googleBusinessLink && (
                <SocialIconLink href={googleBusinessLink} label="Google">
                  <GoogleIcon size={18} />
                </SocialIconLink>
              )}
              {articles.length > 0 && (
                <SocialIconLink href={`/v/${storeSlug}/yazilar`} label="Yazılar">
                  <span className="text-[11px] font-extrabold">Yazı</span>
                </SocialIconLink>
              )}
              {referencesUrl && (
                <SocialIconLink href={referencesUrl} label="Referanslar">
                  <span className="text-[11px] font-extrabold">Ref</span>
                </SocialIconLink>
              )}
            </div>
          ) : null}
        </div>
      </header>

      <main
        className="mx-auto w-full max-w-[1080px]"
        style={{
          paddingLeft: "var(--v-main-pad-x)",
          paddingRight: "var(--v-main-pad-x)",
          paddingTop: "var(--v-main-pad-y)",
          paddingBottom: "var(--v-main-pad-y)",
        }}
      >
        {/* FEED — ürün varsa katalog; hizmet ailesinde ürün yoksa boş state */}
        {(productCount > 0 ||
          collections.length > 0 ||
          profile.family === "service" ||
          profile.family === "venue") && (
          <section
            className="mb-8 animate-fade-in sm:mb-12"
            style={
              {
                ["--vitrin-card-ratio" as string]:
                  profile.family === "service" ? "1 / 1" : "4 / 5",
              } as CSSProperties
            }
          >
            <p
              className="mb-1.5 font-extrabold uppercase tracking-[0.14em] text-[#E8A87C]"
              style={{ fontSize: "var(--v-section-label)" }}
            >
              Vitrin
            </p>
            <h2
              className="mb-4 font-extrabold tracking-[-0.02em] text-white sm:mb-5"
              style={{ fontSize: "var(--v-section-title)" }}
            >
              {profile.sectionTitle}
            </h2>

            {collections.length > 0 && (
              <div className="mb-4 flex flex-wrap gap-2">
                {collections.map((c) => (
                  <span
                    key={c.name}
                    className="rounded-full border border-white/10 bg-[#15171c] px-3.5 py-2 text-[13px] font-bold text-white/60"
                  >
                    {c.name}
                    <span className="ml-1.5 text-white/35">{c.count}</span>
                  </span>
                ))}
              </div>
            )}

            {productCount > 0 ? (
              <Suspense
                fallback={
                  <div
                    className="grid grid-cols-2 md:grid-cols-3"
                    style={{ gap: "var(--v-card-gap)" }}
                  >
                    {Array.from({ length: 6 }).map((_, i) => (
                      <div
                        key={i}
                        className="animate-pulse overflow-hidden border border-white/8 bg-[#15171c]"
                        style={{ borderRadius: "var(--v-card-radius)" }}
                      >
                        <div className="v-product-media bg-[#1c1f27]" />
                        <div className="space-y-2" style={{ padding: "var(--v-card-pad)" }}>
                          <div className="h-3 rounded bg-[#1c1f27]" />
                          <div className="h-3 w-1/2 rounded bg-[#1c1f27]" />
                        </div>
                      </div>
                    ))}
                  </div>
                }
              >
                {catalog}
              </Suspense>
            ) : profile.family === "service" || profile.family === "venue" ? (
              <div className="rounded-[20px] border border-dashed border-white/15 bg-[#15171c] px-6 py-8 text-center">
                <p className="mb-4 text-sm font-semibold text-white/55">{copy.emptyFeed}</p>
                <div className="flex flex-wrap justify-center gap-2.5">
                  {whatsappUrl && (
                    <ActionButton
                      href={whatsappUrl}
                      variant="wa"
                      icon={<WhatsAppIcon className="v-action-icon" size={16} />}
                      ariaLabel={`WhatsApp · ${copy.whatsappButton}`}
                    >
                      {`WhatsApp · ${copy.whatsappButton}`}
                    </ActionButton>
                  )}
                  {isBookingEnabled && (
                    <ActionButton href={`/v/${storeSlug}/randevu`} variant="book">
                      Randevu al
                    </ActionButton>
                  )}
                </div>
              </div>
            ) : null}
          </section>
        )}

        {/* ATMOSPHERE */}
        {(corporateBio || galleryItems.length > 0) && (
          <section className="mb-8 sm:mb-12">
            <p
              className="mb-1.5 font-extrabold uppercase tracking-[0.14em] text-[#E8A87C]"
              style={{ fontSize: "var(--v-section-label)" }}
            >
              Atmosfer
            </p>
            <h2
              className="mb-4 font-extrabold tracking-[-0.02em] text-white sm:mb-5"
              style={{ fontSize: "var(--v-section-title)" }}
            >
              {copy.atmosphereTitle}
            </h2>
            <div className="grid gap-3 sm:gap-4 lg:grid-cols-2">
              {corporateBio && (
                <article className="rounded-2xl border border-white/8 bg-[linear-gradient(160deg,rgba(232,168,124,0.1),transparent_50%),#15171c] p-4 sm:rounded-[20px] sm:p-6">
                  <p
                    className="mb-2 font-extrabold uppercase tracking-[0.12em] text-[#E8A87C] sm:mb-3"
                    style={{ fontSize: "var(--v-section-label)" }}
                  >
                    {copy.storyTitle}
                  </p>
                  <p
                    className="whitespace-pre-wrap font-medium leading-relaxed text-white/82"
                    style={{ fontSize: "var(--v-bio-size)" }}
                  >
                    {corporateBio}
                  </p>
                </article>
              )}
              {galleryItems.length > 0 && (
                <div className="grid grid-cols-3 gap-1 overflow-hidden rounded-2xl sm:gap-1.5 sm:rounded-[20px]">
                  {galleryItems.slice(0, 5).map((item, i) => (
                    <div
                      key={item.id || i}
                      className={`relative bg-[#1c1f27] ${i === 0 ? "col-span-2 row-span-2" : ""}`}
                      style={{
                        minHeight:
                          i === 0 ? "var(--v-gallery-hero-min)" : "var(--v-gallery-tile-min)",
                      }}
                    >
                      <Image
                        src={item.imageUrl}
                        alt={item.title || "Vitrin görseli"}
                        fill
                        className="object-cover"
                        sizes={i === 0 ? "50vw" : "20vw"}
                      />
                    </div>
                  ))}
                </div>
              )}
            </div>
          </section>
        )}

        {/* CONNECT */}
        <section
          className="mb-8 grid gap-4 rounded-2xl border border-white/8 bg-[#15171c] sm:mb-10 sm:gap-5 sm:rounded-[24px] lg:grid-cols-[1.4fr_auto] lg:items-center"
          style={{ padding: "var(--v-connect-pad)" }}
        >
          <div>
            <h2
              className="font-extrabold tracking-[-0.02em] text-white"
              style={{ fontSize: "var(--v-connect-title)" }}
            >
              {copy.connectTitle}
            </h2>
            {displayAddress && (
              <p className="mt-2 text-sm font-semibold text-white/55">{displayAddress}</p>
            )}
            {workingHoursToday && (
              <p className="mt-1 text-xs font-semibold text-white/55">{workingHoursToday}</p>
            )}
            {workingHoursWeek.length > 0 && (
              <details className="mt-2 group">
                <summary className="cursor-pointer text-xs font-bold text-white/40 hover:text-white/70">
                  Tüm hafta
                </summary>
                <ul className="mt-2 space-y-1 text-xs font-semibold text-white/45">
                  {workingHoursWeek.map((row) => (
                    <li
                      key={row.day}
                      className={`flex justify-between gap-4 ${row.isToday ? "text-white/80" : ""}`}
                    >
                      <span>{row.day}</span>
                      <span>{row.hours}</span>
                    </li>
                  ))}
                </ul>
              </details>
            )}

            <div className="mt-4 flex flex-wrap gap-2">
              {mapsUrl && (
                <ActionButton
                  href={mapsUrl}
                  variant="ghost"
                  icon={<MapPinIcon className="v-action-icon" size={16} />}
                  ariaLabel="Yol tarifi"
                >
                  Yol tarifi
                </ActionButton>
              )}
              <a
                href={vcardHref}
                download={`${storeSlug}.vcf`}
                className="v-action-btn inline-flex items-center justify-center rounded-full border border-white/15 bg-transparent font-extrabold text-white"
              >
                Rehbere ekle
              </a>
              {googleBusinessLink && (
                <ActionButton
                  href={googleBusinessLink}
                  variant="ghost"
                  icon={<GoogleIcon className="v-action-icon" size={16} />}
                  ariaLabel="Google yorum"
                >
                  Google yorum
                </ActionButton>
              )}
            </div>

            {marketplaceLinks.length > 0 && (
              <div className="mt-4 flex flex-wrap gap-2">
                {marketplaceLinks.map((link, i) => (
                  <Link
                    key={link.id || i}
                    href={normalizeExternalUrl(link.url) || publicUrl}
                    className="rounded-full border border-white/10 bg-[#0c0d10] px-3 py-2 text-xs font-bold text-white/55 transition hover:text-white"
                  >
                    {link.platform}
                  </Link>
                ))}
              </div>
            )}

            <div className="mt-5 flex flex-wrap gap-x-4 gap-y-2 border-t border-white/8 pt-4 text-[13px] font-bold text-white/45">
              {articles.length > 0 && (
                <Link href={`/v/${storeSlug}/yazilar`} className="hover:text-white">
                  Yazılar
                </Link>
              )}
              {isBookingEnabled && (
                <Link href={`/v/${storeSlug}/randevu`} className="hover:text-white">
                  Randevu
                </Link>
              )}
              {instagramUrl && (
                <Link href={instagramUrl} className="hover:text-white">
                  Instagram
                </Link>
              )}
              {websiteUrl && (
                <Link href={websiteUrl} className="hover:text-white">
                  Web
                </Link>
              )}
              {referencesUrl && (
                <Link href={referencesUrl} className="hover:text-white">
                  Referanslar
                </Link>
              )}
            </div>
          </div>

          <aside className="rounded-2xl border border-white/8 bg-[#1c1f27] p-4 text-center">
            <p className="mb-2 text-[11px] font-extrabold uppercase tracking-[0.08em] text-white/45">
              Vitrini paylaş
            </p>
            <div className="mx-auto mb-3 inline-block rounded-xl bg-white p-1.5 sm:p-2">
              <Image
                src={`https://api.qrserver.com/v1/create-qr-code/?size=140x140&data=${encodeURIComponent(publicUrl)}`}
                alt={`${storeName} QR kodu`}
                width={112}
                height={112}
                style={{ width: "var(--v-qr)", height: "var(--v-qr)" }}
              />
            </div>
            <p className="truncate text-[11px] font-bold text-[#7eb8ff]">{publicUrl}</p>
          </aside>
        </section>

        <footer className="pb-8 text-center text-xs font-semibold text-white/35">
          Bu vitrin Vixrex ile oluşturuldu.
        </footer>
      </main>
    </div>
  );
}
