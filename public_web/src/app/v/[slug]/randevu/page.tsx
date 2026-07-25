import { notFound } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { supabase } from "@/lib/supabase";
import BookingWizardClient from "./BookingWizardClient";

interface PageProps {
  params: Promise<{ slug: string }>;
}

async function getStoreData(slug: string) {
  const { data: store, error } = await supabase
    .from("stores")
    .select("slug, name, logo_url, offerings, status")
    .eq("slug", slug)
    .eq("is_published", true)
    .single();

  if (error || !store) return null;

  const { data: bookingSettings } = await supabase
    .from("booking_settings")
    .select("is_enabled")
    .eq("store_slug", slug)
    .maybeSingle();

  return {
    store,
    isBookingEnabled: bookingSettings?.is_enabled ?? false,
  };
}

export default async function BookingPage(props: PageProps) {
  const params = await props.params;
  const data = await getStoreData(params.slug);
  if (!data || !data.isBookingEnabled) notFound();

  return (
    <div className="min-h-screen bg-[#0c0d10] px-4 py-8 text-[#f4f1ea]">
      <div className="mx-auto flex w-full max-w-lg flex-col gap-6">
        <div className="flex items-center gap-4 rounded-2xl border border-white/8 bg-[#15171c] p-4">
          <Link
            href={`/v/${data.store.slug}`}
            className="rounded-xl border border-[#E8A87C]/30 bg-[#E8A87C]/10 p-2 text-[#E8A87C]"
            aria-label="Vitrine dön"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
            >
              <polyline points="15 18 9 12 15 6" />
            </svg>
          </Link>
          <div className="min-w-0 flex-1">
            <h1 className="truncate text-base font-extrabold text-white">
              {data.store.name}
            </h1>
            <p className="text-xs font-semibold text-white/45">Online randevu</p>
          </div>
          {data.store.logo_url && (
            <Image
              src={data.store.logo_url}
              alt="Logo"
              width={40}
              height={40}
              className="h-10 w-10 rounded-full border border-white/15 bg-white object-contain"
            />
          )}
        </div>

        <BookingWizardClient store={data.store} />
      </div>
    </div>
  );
}
