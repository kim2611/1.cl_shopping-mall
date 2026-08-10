"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useSyncExternalStore } from "react";

import {
  clearSession,
  getAdminName,
  getServerSessionSnapshot,
  getToken,
  SESSION_UNKNOWN,
  subscribeSession,
} from "@/lib/api";

const NAV = [
  { href: "/admin", label: "대시보드" },
  { href: "/admin/orders", label: "주문 관리" },
  { href: "/admin/products", label: "상품 관리" },
] as const;

export default function AdminLayout({ children }: LayoutProps<"/admin">) {
  const router = useRouter();
  const pathname = usePathname();
  // 토큰은 localStorage에 있어 서버 렌더 시점엔 알 수 없다 - 외부 스토어로 구독해서
  // 하이드레이션 후 실제 값으로 렌더된다 (실제 인가는 서버가 /api/admin/**에서 다시 검사).
  const token = useSyncExternalStore(subscribeSession, getToken, getServerSessionSnapshot);
  const name = useSyncExternalStore(subscribeSession, getAdminName, getServerSessionSnapshot);

  useEffect(() => {
    // 아직 하이드레이션 전(모름)일 때는 판단을 미룬다 - 확실히 없을 때만 로그인으로 보낸다.
    if (token !== SESSION_UNKNOWN && !token) {
      router.replace("/login");
    }
  }, [token, router]);

  if (token === SESSION_UNKNOWN || !token) {
    return <main className="flex-1" />;
  }

  return (
    <div className="flex-1 flex flex-col">
      <header className="border-b border-line">
        <div className="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between gap-6">
          <div className="flex items-center gap-8">
            <Link href="/admin" className="font-mono text-sm font-bold uppercase tracking-wide">
              MALL <span className="text-ink-faint">ADMIN</span>
            </Link>
            <nav className="flex gap-1">
              {NAV.map((item) => {
                const active = pathname === item.href;
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={`font-mono text-xs px-3 py-1.5 rounded-sm border ${
                      active
                        ? "bg-accent text-accent-ink border-accent font-bold"
                        : "border-dashed border-line text-ink-soft hover:text-ink"
                    }`}
                  >
                    {item.label}
                  </Link>
                );
              })}
            </nav>
          </div>

          <div className="flex items-center gap-4">
            <span className="font-mono text-[11px] text-ink-faint">
              {name === SESSION_UNKNOWN ? "" : name}
            </span>
            <button
              onClick={() => {
                clearSession();
                router.replace("/login");
              }}
              className="font-mono text-[11px] underline text-ink-soft hover:text-ink"
            >
              로그아웃
            </button>
          </div>
        </div>
      </header>

      <main className="flex-1 max-w-6xl w-full mx-auto px-6 py-8">{children}</main>
    </div>
  );
}
