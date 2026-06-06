import Image from "next/image";
import Link from "next/link";

import { isSupabaseConnected } from "@/lib/supabase/config";

function StatusBadge({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex items-center gap-2 rounded-full border border-[#00d395]/30 bg-[#00d395]/10 px-4 py-1.5 text-xs font-semibold uppercase tracking-[0.2em] text-white backdrop-blur-md shadow-[0_0_15px_rgba(0,211,149,0.15)]">
      <span className="h-1.5 w-1.5 rounded-full bg-[#00d395] animate-pulse" />
      {children}
    </div>
  );
}

export function Header() {
  return (
    <header className="border-b border-white/10 bg-[#080a0d] text-white">
      <div className="mx-auto flex max-w-6xl flex-col items-center gap-4 px-4 py-5 sm:flex-row sm:justify-between">
        <div>
          <Link href="/" className="block">
            <Image
              src="/logo/logo-marketlab.webp"
              alt="MarketLab"
              width={677}
              height={369}
              className="h-24 w-44 object-contain"
              priority
            />
          </Link>
        </div>
        <div className="flex flex-col items-center gap-2 sm:items-end">
          <StatusBadge>Cursor Workshop / Quito</StatusBadge>
          {isSupabaseConnected ? (
            <StatusBadge>Supabase Connected</StatusBadge>
          ) : null}
        </div>
      </div>
    </header>
  );
}
