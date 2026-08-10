"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

import { apiGet, formatWon, UnauthorizedError } from "@/lib/api";

type Stats = {
  orderCount: number;
  netRevenue: number;
  productCount: number;
  memberCount: number;
  lowStockCount: number;
};

export default function DashboardPage() {
  const router = useRouter();
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    apiGet<Stats>("/api/admin/stats")
      .then(setStats)
      .catch((err) => {
        if (err instanceof UnauthorizedError) {
          router.replace("/login");
          return;
        }
        setError(err instanceof Error ? err.message : "불러오지 못했습니다.");
      });
  }, [router]);

  return (
    <div>
      <p className="font-mono text-[11px] tracking-widest uppercase text-ink-faint">
        MALL — DASHBOARD
      </p>
      <h1 className="font-mono text-2xl font-bold uppercase mt-2 mb-8">대시보드</h1>

      {error ? <p className="font-mono text-xs text-stamp mb-6">{error}</p> : null}

      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        <StatCard label="총 주문" value={stats ? `${stats.orderCount}건` : "—"} />
        <StatCard
          label="순매출"
          value={stats ? formatWon(stats.netRevenue) : "—"}
          hint="결제완료 − 환불완료"
          accent
        />
        <StatCard label="등록 상품" value={stats ? `${stats.productCount}개` : "—"} />
        <StatCard label="회원" value={stats ? `${stats.memberCount}명` : "—"} />
        <StatCard
          label="재고 부족"
          value={stats ? `${stats.lowStockCount}개` : "—"}
          hint="20개 미만"
          warn={!!stats && stats.lowStockCount > 0}
        />
      </div>
    </div>
  );
}

function StatCard({
  label,
  value,
  hint,
  accent,
  warn,
}: {
  label: string;
  value: string;
  hint?: string;
  accent?: boolean;
  warn?: boolean;
}) {
  return (
    <div className="border border-line rounded-sm p-5">
      <p className="font-mono text-[11px] uppercase tracking-wide text-ink-faint">{label}</p>
      <p
        className={`font-mono text-xl font-bold mt-3 tabular-nums ${
          warn ? "text-stamp" : accent ? "text-accent" : "text-ink"
        }`}
      >
        {value}
      </p>
      {hint ? <p className="font-mono text-[10px] text-ink-faint mt-1">{hint}</p> : null}
    </div>
  );
}
