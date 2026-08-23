export type VitrinViewSource =
  | "direct"
  | "qr"
  | "share"
  | "unknown"
  | "google"
  | "instagram"
  | "facebook"
  | "whatsapp"
  | "twitter"
  | "tiktok"
  | "diger_site";

const SOCIAL_HOST_PATTERNS: Array<[RegExp, VitrinViewSource]> = [
  [/^(.+\.)?google\.[a-z.]+$|^g\.co$/, "google"],
  [/^(.+\.)?instagram\.[a-z.]+$/, "instagram"],
  [/^(.+\.)?(facebook|fb)\.[a-z.]+$/, "facebook"],
  [/^(.+\.)?whatsapp\.[a-z.]+$|^(.+\.)?wa\.me$/, "whatsapp"],
  [/^(.+\.)?(twitter|x)\.[a-z.]+$|^t\.co$/, "twitter"],
  [/^(.+\.)?tiktok\.[a-z.]+$/, "tiktok"],
];

interface SourceInput {
  srcParam: string | null;
  referrer: string;
  currentHostname: string;
}

export function resolveVitrinViewSource({
  srcParam,
  referrer,
  currentHostname,
}: SourceInput): VitrinViewSource {
  const src = srcParam?.trim().toLowerCase();
  if (src === "qr" || src === "share") return src;

  const trimmedReferrer = referrer.trim();
  if (!trimmedReferrer) return "direct";

  let refHost: string;
  try {
    refHost = new URL(trimmedReferrer).hostname.toLowerCase().replace(/^www\./, "");
  } catch {
    return "unknown";
  }

  if (!refHost) return "unknown";

  if (
    refHost ===
    currentHostname.toLowerCase().replace(/^www\./, "")
  ) {
    return "direct";
  }

  for (const [pattern, source] of SOCIAL_HOST_PATTERNS) {
    if (pattern.test(refHost)) return source;
  }

  return "diger_site";
}
