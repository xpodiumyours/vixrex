import { redirect } from "next/navigation";

function getAppUrl() {
  const configured = process.env.NEXT_PUBLIC_APP_URL?.trim();
  if (!configured) return "https://vixrex-app.vercel.app";
  try {
    return new URL(configured).origin;
  } catch {
    return "https://vixrex-app.vercel.app";
  }
}

/** Root must be a real App Router page so stale static Flutter index cannot own `/`. */
export default function HomePage() {
  redirect(getAppUrl());
}
