/**
 * C7: fatura satırı, üretici doğrulanmasa bile KENDİ kaynak ifadesiyle
 * yalnızca gizli taslak olabilir. Bu bir kimlik eşleşmesi veya yayın kanıtı değildir.
 * Eksik kimliği olmayan satır ise invoice_job_lines içinde saklanır, kart uydurulmaz.
 */
export function otomatikTaslakAdayi(satir: {
  ad?: string | null;
  model?: string | null;
  barkod?: string | null;
  sonuc?: string;
  katalog?: { resmiAd?: string | null; kaynak?: string | null; dayanak?: string | null } | null;
}): boolean {
  return Boolean(satir.ad?.trim() || satir.model?.trim() || satir.barkod?.trim());
}
