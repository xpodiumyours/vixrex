const BOT_UA_PATTERN =
  /(bot|crawler|spider|slurp|bingpreview|facebookexternalhit|whatsapp|telegrambot|discordbot|headlesschrome|lighthouse|pagespeed|uptimerobot|curl|wget|python-requests|go-http-client)/i;

export function isLikelyBotUserAgent(userAgent: string | null | undefined): boolean {
  const value = String(userAgent || "").trim();
  if (!value) return true;
  return BOT_UA_PATTERN.test(value);
}
