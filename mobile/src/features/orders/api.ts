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

/**
 * idempotencyKey를 함께 보내면 같은 키의 재요청은 주문을 새로 만들지 않고 처음 만든 주문을 돌려받는다.
 * (결제 버튼 더블탭, 응답을 못 받고 재시도하는 경우에 주문이 두 건 생기는 걸 막는다.)
 */
export function createOrder(
  accessToken: string,
  payload: CreateOrderPayload,
  idempotencyKey: string
): Promise<Order> {
  return request<Order>('/api/orders', accessToken, {
    method: 'POST',
    headers: { 'Idempotency-Key': idempotencyKey },
    body: JSON.stringify(payload),
  });
}

export function fetchOrders(accessToken: string): Promise<OrderSummary[]> {
  return request<OrderSummary[]>('/api/orders', accessToken);
}

export function fetchOrder(accessToken: string, orderNumber: string): Promise<Order> {
  return request<Order>(`/api/orders/${orderNumber}`, accessToken);
}
