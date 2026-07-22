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
    <div className="container py-8 flex-1 flex flex-col gap-6 max-w-lg">
      {/* Header card */}
      <div className="flex items-center gap-4 bg-white dark:bg-[#131A22] border border-[#D0E4E8] dark:border-[#243141] rounded-2xl p-4 shadow-sm">
        <Link href={`/v/${data.store.slug}`} className="p-2 bg-[#10D8D8]/10 text-[#0EA8B0] rounded-xl">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="15 18 9 12 15 6"/></svg>
        </Link>
        <div className="flex-1 min-w-0">
          <h1 className="font-extrabold text-base truncate">{data.store.name}</h1>
          <p className="text-xs text-[#64748B] dark:text-[#94A3B8]">Online Randevu Sistemi</p>
        </div>
        {data.store.logo_url && (
          <Image src={data.store.logo_url} alt="Logo" width={40} height={40} className="w-10 h-10 rounded-full border object-contain bg-white" />
        )}
      </div>

      {/* Main wizard component */}
      <BookingWizardClient store={data.store} />
    </div>
  );
}
