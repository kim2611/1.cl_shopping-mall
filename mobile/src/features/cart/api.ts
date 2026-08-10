import { API_BASE_URL } from '@/constants/api';

export type CartItem = {
  cartItemId: string;
  productUuid: string;
  productName: string;
  price: number;
  quantity: number;
  lineAmount: number;
  stockQuantity: number;
  thumbnailUrl: string | null;
};

export type Cart = {
  cartId: string | null;
  items: CartItem[];
  totalQuantity: number;
  totalAmount: number;
};

async function request<T>(path: string, accessToken: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
      ...init?.headers,
    },
  });
  if (!res.ok) {
    const body = await res.json().catch(() => null);
    throw new Error(body?.detail ?? `요청이 실패했습니다 (${res.status})`);
  }
  return res.json();
}

export function fetchCart(accessToken: string): Promise<Cart> {
  return request<Cart>('/api/cart', accessToken);
}

export function addCartItem(accessToken: string, productUuid: string, quantity: number): Promise<Cart> {
  return request<Cart>('/api/cart/items', accessToken, {
    method: 'POST',
    body: JSON.stringify({ productUuid, quantity }),
  });
}

export function updateCartItem(accessToken: string, cartItemId: string, quantity: number): Promise<Cart> {
  return request<Cart>(`/api/cart/items/${cartItemId}`, accessToken, {
    method: 'PATCH',
    body: JSON.stringify({ quantity }),
  });
}

export function removeCartItem(accessToken: string, cartItemId: string): Promise<Cart> {
  return request<Cart>(`/api/cart/items/${cartItemId}`, accessToken, { method: 'DELETE' });
}
