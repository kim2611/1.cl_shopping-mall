import { API_BASE_URL } from '@/constants/api';

export type MeResponse = {
  accountId: string;
  name: string;
  email: string | null;
};

export type AuthResponse = {
  accountId: string;
  name: string;
  accessToken: string;
  refreshToken: string;
};

async function parseOrThrow<T>(res: Response): Promise<T> {
  if (!res.ok) {
    const body = await res.json().catch(() => null);
    throw new Error(body?.detail ?? `요청이 실패했습니다 (${res.status})`);
  }
  return res.json();
}

export function login(email: string, password: string): Promise<AuthResponse> {
  return fetch(`${API_BASE_URL}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  }).then((res) => parseOrThrow<AuthResponse>(res));
}

export function signup(email: string, password: string, name: string): Promise<AuthResponse> {
  return fetch(`${API_BASE_URL}/api/auth/signup`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, name }),
  }).then((res) => parseOrThrow<AuthResponse>(res));
}

export function fetchMe(accessToken: string): Promise<MeResponse> {
  return fetch(`${API_BASE_URL}/api/auth/me`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  }).then((res) => parseOrThrow<MeResponse>(res));
}
