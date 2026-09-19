import Link from "next/link";
import { OwnerAuthLayout } from "@/components/owner/OwnerAuthLayout";

export default function SifreSifirlaPage() {
  return (
    <OwnerAuthLayout
      title="Şifre Kullanılmıyor"
      description="Vixrex kalıcı hesaplarda şifre yerine Google hesabı kullanır."
    >
      <p className="text-sm leading-6 text-[var(--owner-muted)]">
        14 günlük kiralık vitrin denemesi için hesap gerekmez. Kalıcı erişim istediğinde Google ile devam edebilirsin.
      </p>
      <Link
        href="/giris"
        className="owner-button-primary mt-5 flex w-full items-center justify-center"
      >
        Google ile Devam Et
      </Link>
      <Link
        href="/kesfet?yalniz_kiralik=1"
        className="owner-button-secondary mt-3 flex w-full items-center justify-center"
      >
        14 Gün Ücretsiz Vitrin Dene
      </Link>
    </OwnerAuthLayout>
  );
}
