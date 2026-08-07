import { redirect } from "next/navigation";
import { getAppUrl } from "@/lib/siteUrl";

/** Root must be a real App Router page so stale static Flutter index cannot own `/`. */
export default function HomePage() {
  redirect(getAppUrl());
}
