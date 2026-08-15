// Google reCAPTCHA v3 sunucu tarafı doğrulaması — tek kaynak.
//
// Önceden bu mantık yalnız /api/verify-recaptcha/route.ts içinde vardı ve
// istemciden fetch ile çağrılıyordu. rent-demo güvenlik açığı kapatılırken
// (2026-08-15) /api/rent-demo'nun da SUNUCU TARAFINDA (istemciden değil,
// kendi POST handler'ının içinde) aynı doğrulamayı yapması gerekti. İkinci
// bir Google-çağırma implementasyonu yazmak yerine mantık buraya çıkarıldı;
// /api/verify-recaptcha da artık bunu kullanıyor — eşik (MIN_SCORE) TEK
// yerde, iki farklı sayı riski yok.

const VERIFY_URL = "https://www.google.com/recaptcha/api/siteverify";

/** Proje genelinde varsayılan eşik — /api/verify-recaptcha'nın önceki
 * sabit değeriyle aynı. Daha maliyetli bir eylem (ör. veri üretimi) için
 * çağıran taraf `minScore` ile daha sıkı bir değer geçebilir. */
export const DEFAULT_MIN_SCORE = 0.3;

export interface RecaptchaVerifyResult {
  success: boolean;
  score?: number;
  action?: string;
  error?: string;
  errorCodes?: string[];
}

interface GoogleRecaptchaResponse {
  success?: boolean;
  score?: number;
  action?: string;
  "error-codes"?: string[];
}

export async function verifyRecaptchaToken(
  token: string,
  expectedAction: string,
  options: { minScore?: number } = {}
): Promise<RecaptchaVerifyResult> {
  const secretKey = process.env.RECAPTCHA_SECRET_KEY?.trim();
  if (!secretKey) {
    return { success: false, error: "reCAPTCHA secret key not configured" };
  }

  const trimmedToken = token.trim();
  const trimmedAction = expectedAction.trim();
  if (!trimmedToken || !trimmedAction) {
    return { success: false, error: "Token and action are required" };
  }

  const minScore = options.minScore ?? DEFAULT_MIN_SCORE;

  let data: GoogleRecaptchaResponse;
  try {
    const params = new URLSearchParams({
      secret: secretKey,
      response: trimmedToken,
    });
    const response = await fetch(VERIFY_URL, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: params,
    });
    if (!response.ok) {
      throw new Error(`Google verification request failed: ${response.status}`);
    }
    data = (await response.json()) as GoogleRecaptchaResponse;
  } catch (error) {
    console.error("[reCAPTCHA] Verify error:", error);
    return { success: false, error: "Internal server error" };
  }

  if (!data.success) {
    return {
      success: false,
      error: "reCAPTCHA verification failed",
      errorCodes: data["error-codes"],
    };
  }

  if (data.action !== trimmedAction) {
    return { success: false, error: "Action mismatch" };
  }

  if (typeof data.score !== "number" || data.score < minScore) {
    return { success: false, error: "Score too low", score: data.score };
  }

  return { success: true, score: data.score, action: data.action };
}
