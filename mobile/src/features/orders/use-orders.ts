import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { useAuthStore } from '@/features/auth/store';
import { createOrder, fetchOrder, fetchOrders, type CreateOrderPayload } from './api';

export function useOrders() {
  const accessToken = useAuthStore((s) => s.accessToken);
  const accountId = useAuthStore((s) => s.account?.accountId);

  return useQuery({
    queryKey: ['orders', accountId ?? 'anonymous'],
    queryFn: () => fetchOrders(accessToken!),
    enabled: !!accessToken,
  });
}

export function useOrder(orderNumber: string) {
  const accessToken = useAuthStore((s) => s.accessToken);

  return useQuery({
    queryKey: ['order', orderNumber],
    queryFn: () => fetchOrder(accessToken!, orderNumber),
    enabled: !!accessToken && !!orderNumber,
  });
}

/**
 * idempotencyKey는 "이 결제 시도" 하나를 가리키는 값이라 호출부(주문서 화면)가 화면 진입 시 한 번 만들어
 * 넘긴다 - 그래야 재시도할 때 같은 키가 유지되고, 새로 주문서에 들어오면 새 키가 된다.
 */
export function useCreateOrder(idempotencyKey: string) {
  const accessToken = useAuthStore((s) => s.accessToken);
  const accountId = useAuthStore((s) => s.account?.accountId);
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: CreateOrderPayload) => createOrder(accessToken!, payload, idempotencyKey),
    onSuccess: () => {
      // 주문이 성사되면 장바구니는 비워지고 주문 목록엔 새 건이 생기므로 둘 다 무효화한다.
      queryClient.invalidateQueries({ queryKey: ['cart', accountId ?? 'anonymous'] });
      queryClient.invalidateQueries({ queryKey: ['orders', accountId ?? 'anonymous'] });
    },
  });
}
