const temizlenecekDegiskenler = [
  "VERCEL_ENV",
  "SUPABASE_URL",
  "NEXT_PUBLIC_SUPABASE_URL",
  "SUPABASE_PUBLISHABLE_KEY",
  "NEXT_PUBLIC_SUPABASE_ANON_KEY",
  "SUPABASE_SERVICE_ROLE_KEY",
  "OWNER_SESSION_SECRET",
  "OPENROUTER_API_KEY",
  "OPENAI_API_KEY",
];

for (const degisken of temizlenecekDegiskenler) {
  delete process.env[degisken];
}
