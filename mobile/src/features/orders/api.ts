import { API_BASE_URL } from '@/constants/api';

export type OrderItem = {
  orderItemId: string;
  productUuid: string | null;
  productName: string;
  optionSummary: string | null;
  quantity: number;
  price: number;
  lineAmount: number;
  thumbnailUrl: string | null;
};

export type Order = {
  orderNumber: string;
  statusName: string;
  orderedAt: string;
  recipientName: string;
  phone: string;
  zipCode: string;
  address1: string;
  address2: string | null;
  items: OrderItem[];
  itemsAmount: number;
  deliveryFee: number;
  discountAmount: number;
  totalAmount: number;
  paymentMethodName: string | null;
  paymentStatusName: string | null;
};

export type OrderSummary = {
  orderNumber: string;
  statusName: string;
  orderedAt: string;
  representativeProductName: string | null;
  itemCount: number;
  totalAmount: number;
  thumbnailUrl: string | null;
};

export type CreateOrderPayload = {
  recipientName: string;
  phone: string;
  zipCode: string;
  address1: string;
  address2?: string;
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

export function createOrder(accessToken: string, payload: CreateOrderPayload): Promise<Order> {
  return request<Order>('/api/orders', accessToken, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function fetchOrders(accessToken: string): Promise<OrderSummary[]> {
  return request<OrderSummary[]>('/api/orders', accessToken);
}

export function fetchOrder(accessToken: string, orderNumber: string): Promise<Order> {
  return request<Order>(`/api/orders/${orderNumber}`, accessToken);
}
