type AuthKullanicisi = {
  is_anonymous?: boolean | null;
};

/**
 * Flutter ile aynı sahiplik sırası:
 * anonim oturum vitrini cihaz erişimiyle yayınlar, kalıcı hesaba bağlama
 * işlemi kullanıcı Google kimliğini ekledikten sonra yapılır.
 */
export function yayinSahiplikKarari(kullanici: AuthKullanicisi) {
  const hesapKorumasiz = kullanici.is_anonymous === true;

  return {
    claimStore: !hesapKorumasiz,
    hesapKorumasiz,
  } as const;
}
