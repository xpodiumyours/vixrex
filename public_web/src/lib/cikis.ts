export type CikisIstemci = {
  signOut: (secenek: { scope: "global" }) => Promise<{ error: { message: string } | null }>;
};

export type CikisYonlendirici = {
  replace: (yol: string) => void;
  refresh: () => void;
};

export async function globalCikisYap(
  istemci: CikisIstemci,
  yonlendirici: CikisYonlendirici,
): Promise<{ ok: boolean; hata: string | null }> {
  const { error } = await istemci.signOut({ scope: "global" });
  if (error) {
    return { ok: false, hata: "Çıkış yapılamadı. Lütfen tekrar deneyin." };
  }
  yonlendirici.replace("/");
  yonlendirici.refresh();
  return { ok: true, hata: null };
}
