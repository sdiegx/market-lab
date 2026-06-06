import { z } from "zod";

const envSchema = z.object({
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: z.string().min(1).optional(),
  NEXT_PUBLIC_SUPABASE_URL: z.string().url().optional(),
  SUPABASE_PROJECT_REF: z.string().min(1).optional(),
});

function readEnv(name: keyof z.infer<typeof envSchema>) {
  return process.env[name] || undefined;
}

export const env = envSchema.parse({
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: readEnv(
    "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY",
  ),
  NEXT_PUBLIC_SUPABASE_URL: readEnv("NEXT_PUBLIC_SUPABASE_URL"),
  SUPABASE_PROJECT_REF: readEnv("SUPABASE_PROJECT_REF"),
});
