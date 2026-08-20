import { createClient } from '@supabase/supabase-js';

const configuredSupabaseUrl = (
  process.env.SUPABASE_URL ||
  process.env.NEXT_PUBLIC_SUPABASE_URL ||
  ''
).trim();
const configuredSupabaseAnonKey = (
  process.env.SUPABASE_PUBLISHABLE_KEY ||
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  ''
).trim();

export function isSupabaseConfigured(): boolean {
  return Boolean(configuredSupabaseUrl && configuredSupabaseAnonKey);
}

const supabaseUrl =
  configuredSupabaseUrl || 'https://placeholder-url.supabase.co';
const supabaseAnonKey = configuredSupabaseAnonKey || 'placeholder-anon-key';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
