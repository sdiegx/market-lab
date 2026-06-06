import { env } from "@/env";

export const isSupabaseConfigured = Boolean(
  env.NEXT_PUBLIC_SUPABASE_URL && env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
);

export const isSupabaseConnected = Boolean(
  env.NEXT_PUBLIC_SUPABASE_URL &&
    env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY &&
    env.SUPABASE_PROJECT_REF,
);

export function getSupabaseConfig() {
  if (!isSupabaseConfigured) {
    return null;
  }

  return {
    publishableKey: env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY as string,
    url: env.NEXT_PUBLIC_SUPABASE_URL as string,
  };
}
