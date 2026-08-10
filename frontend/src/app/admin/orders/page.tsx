"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { apiGet, apiPatch, formatWon, UnauthorizedError } from "@/lib/api";

type OrderRow = {
  orderNumber: string;
  orderedAt: string;
  buyerName: string | null;
  recipientName: string;
  itemCount: number;
  totalAmount: number;
  statusName: string | null;
  statusCode: string | null;
};

type Paged<T> = {
  content: T[];
  page: { size: number; number: number; totalElements: number; totalPages: number };
};

const ORDER_STATUSES = [
  { code: "ORST0001", name: "주문대기" },
  { code: "ORST0002", name: "결제완료" },
  { code: "ORST0003", name: "배송중" },
  { code: "ORST0004", name: "배송완료" },
  { code: "ORST0005", name: "취소" },
];

export default function AdminOrdersPage() {
  const router = useRouter();
  const [data, setData] = useState<Paged<OrderRow> | null>(null);
  const [page, setPage] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [savingOrder, setSavingOrder] = useState<string | null>(null);

  const load = useCallback(
    (pageNumber: number) => {
      apiGet<Paged<OrderRow>>(`/api/admin/orders?page=${pageNumber}&size=20`)
        .then(setData)
        .catch((err) => {
          if (err instanceof UnauthorizedError) {
            router.replace("/login");
            return;
          }
          setError(err instanceof Error ? err.message : "불러오지 못했습니다.");
        });
    },
    [router]
  );

  useEffect(() => {
    load(page);
  }, [load, page]);

  async function changeStatus(orderNumber: string, statusCode: string) {
    setSavingOrder(orderNumber);
    setError(null);
    try {
      const updated = await apiPatch<OrderRow>(`/api/admin/orders/${orderNumber}/status`, {
        statusCode,
      });
      setData((prev) =>
        prev
          ? {
              ...prev,
              content: prev.content.map((row) =>
                row.orderNumber === updated.orderNumber ? updated : row
              ),
            }
          : prev
      );
    } catch (err) {
      if (err instanceof UnauthorizedError) {
        router.replace("/login");
        return;
      }
      setError(err instanceof Error ? err.message : "상태 변경에 실패했습니다.");
    } finally {
      setSavingOrder(null);
    }
  }

  return (
    <div>
      <p className="font-mono text-[11px] tracking-widest uppercase text-ink-faint">
        MALL — ORDERS
      </p>
      <h1 className="font-mono text-2xl font-bold uppercase mt-2 mb-8">주문 관리</h1>

      {error ? <p className="font-mono text-xs text-stamp mb-4">{error}</p> : null}

      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-line">
              <Th>주문번호</Th>
              <Th>주문일</Th>
              <Th>주문자</Th>
              <Th>수령인</Th>
              <Th align="right">수량</Th>
              <Th align="right">금액</Th>
              <Th>상태</Th>
            </tr>
          </thead>
          <tbody>
            {data?.content.map((row) => (
              <tr key={row.orderNumber} className="rule-dashed">
                <Td mono>{row.orderNumber}</Td>
                <Td>{new Date(row.orderedAt).toLocaleDateString("ko-KR")}</Td>
                <Td>{row.buyerName ?? "—"}</Td>
                <Td>{row.recipientName}</Td>
                <Td align="right" mono>
                  {row.itemCount}
                </Td>
                <Td align="right" mono>
                  {formatWon(row.totalAmount)}
                </Td>
                <Td>
                  <select
                    value={row.statusCode ?? ""}
                    disabled={savingOrder === row.orderNumber}
                    onChange={(e) => changeStatus(row.orderNumber, e.target.value)}
                    className="font-mono text-xs border border-dashed border-line rounded-sm px-2 py-1 bg-paper focus:outline-none focus:border-solid focus:border-accent"
                  >
                    {ORDER_STATUSES.map((s) => (
                      <option key={s.code} value={s.code}>
                        {s.name}
                      </option>
                    ))}
                  </select>
                </Td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {data && data.content.length === 0 ? (
        <p className="font-mono text-xs text-ink-faint py-10 text-center">주문이 없습니다.</p>
      ) : null}

      {data && data.page.totalPages > 1 ? (
        <Pagination
          page={data.page.number}
          totalPages={data.page.totalPages}
          onChange={setPage}
        />
      ) : null}
    </div>
  );
}

function Th({ children, align }: { children: React.ReactNode; align?: "right" }) {
  return (
    <th
      className={`font-mono text-[10px] uppercase tracking-wide font-normal text-ink-faint pb-2.5 ${
        align === "right" ? "text-right" : "text-left"
      }`}
    >
      {children}
    </th>
  );
}

function Td({
  children,
  align,
  mono,
}: {
  children: React.ReactNode;
  align?: "right";
  mono?: boolean;
}) {
  return (
    <td
      className={`py-3 ${align === "right" ? "text-right" : "text-left"} ${
        mono ? "font-mono tabular-nums" : ""
      }`}
    >
      {children}
    </td>
  );
}

function Pagination({
  page,
  totalPages,
  onChange,
}: {
  page: number;
  totalPages: number;
  onChange: (page: number) => void;
}) {
  return (
    <div className="flex items-center justify-center gap-3 mt-8 font-mono text-xs">
      <button
        disabled={page === 0}
        onClick={() => onChange(page - 1)}
        className="px-3 py-1.5 border border-dashed border-line rounded-sm disabled:text-ink-faint"
      >
        이전
      </button>
      <span className="tabular-nums text-ink-soft">
        {page + 1} / {totalPages}
      </span>
      <button
        disabled={page >= totalPages - 1}
        onClick={() => onChange(page + 1)}
        className="px-3 py-1.5 border border-dashed border-line rounded-sm disabled:text-ink-faint"
      >
        다음
      </button>
    </div>
  );
}
