"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

import { login, setSession } from "@/lib/api";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("admin@mall.test");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setPending(true);
    try {
      const res = await login(email, password);
      // 관리자 콘솔이므로 일반 회원 계정은 여기서 막는다 (서버도 /api/admin/**를 ADMIN으로 제한).
      if (res.role !== "ADMIN") {
        setError("관리자 계정으로만 로그인할 수 있습니다.");
        return;
      }
      setSession(res.accessToken, res.name);
      router.replace("/admin");
    } catch (err) {
      setError(err instanceof Error ? err.message : "로그인에 실패했습니다.");
    } finally {
      setPending(false);
    }
  }

  return (
    <main className="flex-1 flex items-center justify-center p-6">
      <form onSubmit={onSubmit} className="w-full max-w-sm">
        <p className="font-mono text-[11px] tracking-widest uppercase text-ink-faint">
          MALL — ADMIN CONSOLE
        </p>
        <h1 className="font-mono text-2xl font-bold uppercase mt-2 mb-8">로그인</h1>

        <label className="block mb-5">
          <span className="font-mono text-[11px] uppercase tracking-wide text-ink-soft">이메일</span>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            className="mt-2 w-full border border-dashed border-ink-faint rounded-sm px-3 py-2.5 text-sm bg-paper focus:outline-none focus:border-solid focus:border-accent"
          />
        </label>

        <label className="block mb-6">
          <span className="font-mono text-[11px] uppercase tracking-wide text-ink-soft">비밀번호</span>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            className="mt-2 w-full border border-dashed border-ink-faint rounded-sm px-3 py-2.5 text-sm bg-paper focus:outline-none focus:border-solid focus:border-accent"
          />
        </label>

        {error ? <p className="font-mono text-[11px] text-stamp mb-4">{error}</p> : null}

        <button
          type="submit"
          disabled={pending}
          className="w-full bg-accent text-accent-ink font-mono text-xs font-bold uppercase tracking-wide py-3 rounded-sm disabled:bg-surface disabled:text-ink-faint"
        >
          {pending ? "로그인 중..." : "로그인"}
        </button>

        <p className="font-mono text-[11px] text-ink-faint mt-6">
          테스트 계정: admin@mall.test / Mall!2026
        </p>
      </form>
    </main>
  );
}
