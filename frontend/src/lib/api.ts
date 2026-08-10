export const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8090";

const TOKEN_KEY = "mall-admin-token";
const NAME_KEY = "mall-admin-name";

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(TOKEN_KEY);
}

export function setSession(token: string, name: string) {
  window.localStorage.setItem(TOKEN_KEY, token);
  window.localStorage.setItem(NAME_KEY, name);
  notifySessionChanged();
}

export function getAdminName(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(NAME_KEY);
}

export function clearSession() {
  window.localStorage.removeItem(TOKEN_KEY);
  window.localStorage.removeItem(NAME_KEY);
  notifySessionChanged();
}

/**
 * localStorage 세션을 React가 구독할 수 있는 외부 스토어로 노출한다.
 * (effect 안에서 setState로 읽으면 불필요한 연쇄 렌더가 생기고 lint에도 걸린다.
 *  useSyncExternalStore를 쓰면 다른 탭에서 로그아웃한 경우도 storage 이벤트로 같이 반영된다.)
 */
const SESSION_EVENT = "mall-admin-session";
const sessionListeners = new Set<() => void>();

function notifySessionChanged() {
  sessionListeners.forEach((listener) => listener());
}

export function subscribeSession(listener: () => void): () => void {
  sessionListeners.add(listener);
  window.addEventListener("storage", listener);
  window.addEventListener(SESSION_EVENT, listener);
  return () => {
    sessionListeners.delete(listener);
    window.removeEventListener("storage", listener);
    window.removeEventListener(SESSION_EVENT, listener);
  };
}

/**
 * 서버 렌더/하이드레이션 시점에는 localStorage를 볼 수 없다. 이때 null을 반환하면
 * "로그아웃 상태"와 구분이 안 돼서, 하이드레이션 직후 이펙트가 로그인 화면으로 튕겨버린다(실제로 겪음).
 * 그래서 "아직 모름"을 뜻하는 센티널을 따로 둔다.
 */
export const SESSION_UNKNOWN = "__session_unknown__";

export function getServerSessionSnapshot(): string {
  return SESSION_UNKNOWN;
}

/** 인증이 만료/무효면 던지는 에러 - 화면에서 로그인으로 되돌릴 때 구분용. */
export class UnauthorizedError extends Error {
  constructor() {
    super("로그인이 필요합니다.");
  }
}

async function parseError(res: Response): Promise<never> {
  if (res.status === 401 || res.status === 403) {
    throw new UnauthorizedError();
  }
  const body = await res.json().catch(() => null);
  throw new Error(body?.detail ?? `요청이 실패했습니다 (${res.status})`);
}

export async function apiGet<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE_URL}${path}`, {
    headers: { Authorization: `Bearer ${getToken() ?? ""}` },
  });
  if (!res.ok) await parseError(res);
  return res.json();
}

export async function apiPatch<T>(path: string, body: unknown): Promise<T> {
  const res = await fetch(`${API_BASE_URL}${path}`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${getToken() ?? ""}`,
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) await parseError(res);
  return res.json();
}

export async function login(email: string, password: string) {
  const res = await fetch(`${API_BASE_URL}/api/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });
  if (!res.ok) {
    const body = await res.json().catch(() => null);
    throw new Error(body?.detail ?? "로그인에 실패했습니다.");
  }
  return res.json() as Promise<{
    accountId: string;
    name: string;
    role: string;
    accessToken: string;
    refreshToken: string;
  }>;
}

export function resolveImageUrl(path: string | null): string | null {
  if (!path) return null;
  return path.startsWith("http") ? path : `${API_BASE_URL}${path}`;
}

export function formatWon(amount: number): string {
  return `${Number(amount).toLocaleString("ko-KR")}원`;
}
