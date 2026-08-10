import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';
import { create } from 'zustand';
import { createJSONStorage, persist, type StateStorage } from 'zustand/middleware';

import { fetchMe, login as loginApi, signup as signupApi, type MeResponse } from './api';

type AuthState = {
  accessToken: string | null;
  refreshToken: string | null;
  account: MeResponse | null;
  isLoading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  signup: (email: string, password: string, name: string) => Promise<void>;
  logout: () => void;
  hydrateMe: () => Promise<void>;
};

// expo-secure-store는 웹에서 실제로는 동작하지 않는다(OS 키체인이 없음 - web.js 파일은
// 있지만 setValueWithKeyAsync가 구현돼 있지 않아 호출하면 조용히 실패한다). 네이티브에서만
// SecureStore를 쓰고, 웹에서는 localStorage로 대체한다 (토큰 보안 수준은 네이티브보다 낮지만
// 웹은 애초에 브라우저 미리보기/개발용이라 감수).
const secureStorage: StateStorage = {
  getItem: (name) => SecureStore.getItemAsync(name),
  setItem: (name, value) => SecureStore.setItemAsync(name, value),
  removeItem: (name) => SecureStore.deleteItemAsync(name),
};

const webStorage: StateStorage = {
  getItem: (name) => Promise.resolve(globalThis.localStorage?.getItem(name) ?? null),
  setItem: (name, value) => {
    globalThis.localStorage?.setItem(name, value);
    return Promise.resolve();
  },
  removeItem: (name) => {
    globalThis.localStorage?.removeItem(name);
    return Promise.resolve();
  },
};

const platformStorage = Platform.OS === 'web' ? webStorage : secureStorage;

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      accessToken: null,
      refreshToken: null,
      account: null,
      isLoading: false,
      error: null,

      login: async (email, password) => {
        set({ isLoading: true, error: null });
        try {
          const res = await loginApi(email, password);
          set({
            accessToken: res.accessToken,
            refreshToken: res.refreshToken,
            account: { accountId: res.accountId, name: res.name, email },
          });
        } catch (e) {
          set({ error: e instanceof Error ? e.message : '로그인에 실패했습니다.' });
          throw e;
        } finally {
          set({ isLoading: false });
        }
      },

      signup: async (email, password, name) => {
        set({ isLoading: true, error: null });
        try {
          const res = await signupApi(email, password, name);
          set({
            accessToken: res.accessToken,
            refreshToken: res.refreshToken,
            account: { accountId: res.accountId, name: res.name, email },
          });
        } catch (e) {
          set({ error: e instanceof Error ? e.message : '회원가입에 실패했습니다.' });
          throw e;
        } finally {
          set({ isLoading: false });
        }
      },

      logout: () => set({ accessToken: null, refreshToken: null, account: null }),

      hydrateMe: async () => {
        const token = get().accessToken;
        if (!token) return;
        try {
          const me = await fetchMe(token);
          set({ account: me });
        } catch {
          // 토큰 만료/무효 - 조용히 로그아웃 처리
          set({ accessToken: null, refreshToken: null, account: null });
        }
      },
    }),
    {
      name: 'mall-auth',
      storage: createJSONStorage(() => platformStorage),
      partialize: (state) => ({ accessToken: state.accessToken, refreshToken: state.refreshToken }),
      onRehydrateStorage: () => (state) => {
        state?.hydrateMe();
      },
    }
  )
);
