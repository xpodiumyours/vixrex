import { NextResponse } from "next/server";

/**
 * Fatura okuyucusu kullanıma hazır mı?
 *
 * "Faturadan Ekle" düğmesi bu cevaba göre gösterilir. Okuyucu anahtarı
 * tanımlı değilse düğme hiç çıkmaz — esnaf çalışmayacak bir düğmeye basıp
 * hata görmez.
 *
 * Yalnız EVET/HAYIR döner; anahtarın kendisi ya da herhangi bir parçası
 * dışarı verilmez.
 */
export const dynamic = "force-dynamic";

export async function GET() {
  return NextResponse.json({ hazir: Boolean(process.env.OPENROUTER_API_KEY) });
}
