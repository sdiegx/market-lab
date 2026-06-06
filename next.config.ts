import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  allowedDevOrigins: ["127.0.0.1"],
  images: {
    remotePatterns: [
      {
        hostname: "*.supabase.co",
        protocol: "https",
      },
      {
        hostname: "127.0.0.1",
        pathname: "/storage/v1/object/public/**",
        port: "54321",
        protocol: "http",
      },
      {
        hostname: "localhost",
        pathname: "/storage/v1/object/public/**",
        port: "54321",
        protocol: "http",
      },
    ],
  },
};

export default nextConfig;
