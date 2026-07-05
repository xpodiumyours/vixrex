import { notFound } from "next/navigation";
import { supabase } from "@/lib/supabase";
import BookingTrackerClient from "./BookingTrackerClient";

interface PageProps {
  params: Promise<{ slug: string; token: string }>;
}

async function getAppointmentData(token: string) {
  const { data, error } = await supabase.rpc("get_appointment_by_token", {
    p_token: token,
  });

  if (error || !data) return null;
  return data;
}

export async function generateMetadata() {
  return {
    title: "Randevu Takip - VixRex",
    robots: "noindex, nofollow", // Do not index personal tracking links
  };
}

export default async function BookingTrackerPage(props: PageProps) {
  const params = await props.params;
  const appointment = await getAppointmentData(params.token);
  if (!appointment) notFound();

  return (
    <div className="container py-8 flex-1 flex flex-col gap-6 max-w-lg">
      {/* Tracker Card Wrapper */}
      <BookingTrackerClient initialAppointment={appointment} token={params.token} />
    </div>
  );
}
