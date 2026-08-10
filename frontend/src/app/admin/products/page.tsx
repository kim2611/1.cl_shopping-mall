"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { apiGet, apiPatch, resolveImageUrl, UnauthorizedError } from "@/lib/api";

type ProductRow = {
  uuid: string;
  name: string;
  categoryName: string | null;
  price: number;
  stockQuantity: number;
  statusName: string | null;
  statusCode: string | null;
  thumbnailUrl: string | null;
};

type Paged<T> = {
  content: T[];
  page: { size: number; number: number; totalElements: number; totalPages: number };
};

const PRODUCT_STATUSES = [
  { code: "PRST0001", name: "판매중" },
  { code: "PRST0002", name: "품절" },
  { code: "PRST0003", name: "숨김" },
];

const LOW_STOCK = 20;

export default function AdminProductsPage() {
  const router = useRouter();
  const [data, setData] = useState<Paged<ProductRow> | null>(null);
  const [page, setPage] = useState(0);
  const [error, setError] = useState<string | null>(null);
  /** 편집 중인 행의 입력값 (저장 전까지는 서버 값과 별개로 들고 있는다). */
  const [drafts, setDrafts] = useState<Record<string, { price: string; stock: string }>>({});
  const [saving, setSaving] = useState<string | null>(null);

  const load = useCallback(
    (pageNumber: number) => {
      apiGet<Paged<ProductRow>>(`/api/admin/products?page=${pageNumber}&size=20`)
        .then((res) => {
          setData(res);
          setDrafts({});
        })
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

  function draftOf(row: ProductRow) {
    return drafts[row.uuid] ?? { price: String(row.price), stock: String(row.stockQuantity) };
  }

  function setDraft(uuid: string, patch: Partial<{ price: string; stock: string }>) {
    setDrafts((prev) => {
      const row = data?.content.find((r) => r.uuid === uuid);
      const base = prev[uuid] ?? {
        price: String(row?.price ?? ""),
        stock: String(row?.stockQuantity ?? ""),
      };
      return { ...prev, [uuid]: { ...base, ...patch } };
    });
  }

  async function save(row: ProductRow, patch: Record<string, unknown>) {
    setSaving(row.uuid);
    setError(null);
    try {
      const updated = await apiPatch<ProductRow>(`/api/admin/products/${row.uuid}`, patch);
      setData((prev) =>
        prev
          ? { ...prev, content: prev.content.map((r) => (r.uuid === updated.uuid ? updated : r)) }
          : prev
      );
      setDrafts((prev) => {
        const next = { ...prev };
        delete next[row.uuid];
        return next;
      });
    } catch (err) {
      if (err instanceof UnauthorizedError) {
        router.replace("/login");
        return;
      }
      setError(err instanceof Error ? err.message : "저장에 실패했습니다.");
    } finally {
      setSaving(null);
    }
  }

  return (
    <div>
      <p className="font-mono text-[11px] tracking-widest uppercase text-ink-faint">
        MALL — PRODUCTS
      </p>
      <h1 className="font-mono text-2xl font-bold uppercase mt-2 mb-2">상품 관리</h1>
      <p className="font-mono text-[11px] text-ink-faint mb-8">
        가격·재고를 고치면 저장 버튼이 활성화됩니다. 재고를 바꾸면 재고 이력에도 기록됩니다.
      </p>

      {error ? <p className="font-mono text-xs text-stamp mb-4">{error}</p> : null}

      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-line">
              <Th>상품</Th>
              <Th>카테고리</Th>
              <Th align="right">가격</Th>
              <Th align="right">재고</Th>
              <Th>상태</Th>
              <Th></Th>
            </tr>
          </thead>
          <tbody>
            {data?.content.map((row) => {
              const draft = draftOf(row);
              const dirty =
                draft.price !== String(row.price) || draft.stock !== String(row.stockQuantity);
              const thumbnail = resolveImageUrl(row.thumbnailUrl);
              return (
                <tr key={row.uuid} className="rule-dashed">
                  <td className="py-3">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-12 bg-surface flex items-center justify-center shrink-0">
                        {thumbnail ? (
                          // 시드 이미지가 SVG라 next/image 최적화 대상이 아니고, 크기도 고정이라 img로 충분
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={thumbnail} alt="" className="w-full h-full object-contain" />
                        ) : null}
                      </div>
                      <span>{row.name}</span>
                    </div>
                  </td>
                  <Td>{row.categoryName ?? "—"}</Td>
                  <td className="py-3 text-right">
                    <input
                      type="number"
                      value={draft.price}
                      onChange={(e) => setDraft(row.uuid, { price: e.target.value })}
                      className="w-28 text-right font-mono tabular-nums text-xs border border-dashed border-line rounded-sm px-2 py-1 bg-paper focus:outline-none focus:border-solid focus:border-accent"
                    />
                  </td>
                  <td className="py-3 text-right">
                    <input
                      type="number"
                      value={draft.stock}
                      onChange={(e) => setDraft(row.uuid, { stock: e.target.value })}
                      className={`w-20 text-right font-mono tabular-nums text-xs border border-dashed rounded-sm px-2 py-1 bg-paper focus:outline-none focus:border-solid focus:border-accent ${
                        row.stockQuantity < LOW_STOCK ? "border-stamp text-stamp" : "border-line"
                      }`}
                    />
                  </td>
                  <Td>
                    <select
                      value={row.statusCode ?? ""}
                      disabled={saving === row.uuid}
                      onChange={(e) => save(row, { statusCode: e.target.value })}
                      className="font-mono text-xs border border-dashed border-line rounded-sm px-2 py-1 bg-paper focus:outline-none focus:border-solid focus:border-accent"
                    >
                      {PRODUCT_STATUSES.map((s) => (
                        <option key={s.code} value={s.code}>
                          {s.name}
                        </option>
                      ))}
                    </select>
                  </Td>
                  <td className="py-3 text-right">
                    <button
                      disabled={!dirty || saving === row.uuid}
                      onClick={() =>
                        save(row, {
                          price: Number(draft.price),
                          stockQuantity: Number(draft.stock),
                        })
                      }
                      className="font-mono text-[11px] font-bold uppercase px-3 py-1.5 rounded-sm bg-accent text-accent-ink disabled:bg-surface disabled:text-ink-faint"
                    >
                      {saving === row.uuid ? "저장 중" : "저장"}
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {data && data.page.totalPages > 1 ? (
        <Pagination page={data.page.number} totalPages={data.page.totalPages} onChange={setPage} />
      ) : null}
    </div>
  );
}

function Th({ children, align }: { children?: React.ReactNode; align?: "right" }) {
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

function Td({ children, align }: { children: React.ReactNode; align?: "right" }) {
  return <td className={`py-3 ${align === "right" ? "text-right" : "text-left"}`}>{children}</td>;
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
