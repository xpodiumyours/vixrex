export type CikisIstemci = {
  signOut: (secenek: { scope: "global" }) => Promise<{ error: { message: string } | null }>;
};

export type CikisYonlendirici = {
  replace: (yol: string) => void;
  refresh: () => void;
};

export type CikisCerezTemizleyici = () => Promise<Response>;

const HATA_MESAJI = "Çıkış yapılamadı. Lütfen tekrar deneyin.";

export async function globalCikisYap(
  istemci: CikisIstemci,
  yonlendirici: CikisYonlendirici,
  cerezTemizleyici: CikisCerezTemizleyici = () =>
    fetch("/api/owner-session", { method: "DELETE" }),
): Promise<{ ok: boolean; hata: string | null }> {
  try {
    const { error } = await istemci.signOut({ scope: "global" });
    if (error) return { ok: false, hata: HATA_MESAJI };
  } catch {
    return { ok: false, hata: HATA_MESAJI };
  }

  await cerezTemizleyici().catch(() => undefined);

  yonlendirici.replace("/");
  yonlendirici.refresh();
  return { ok: true, hata: null };
}
