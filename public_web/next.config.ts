import type { NextConfig } from "next";

const fallbackAppUrl = "https://vitrinx-two.vercel.app";

function getAppUrl() {
  const configured = process.env.NEXT_PUBLIC_APP_URL?.trim();
  if (!configured) return fallbackAppUrl;

  try {
    return new URL(configured).origin;
  } catch {
    return fallbackAppUrl;
  }
}

const nextConfig: NextConfig = {
  async redirects() {
    return [
      {
        source: "/",
        destination: getAppUrl(),
        permanent: false,
      },
    ];
  },
};

export default nextConfig;
