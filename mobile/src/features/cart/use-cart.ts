import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { useAuthStore } from '@/features/auth/store';
import { addCartItem, fetchCart, removeCartItem, updateCartItem, type Cart } from './api';

/** 계정별로 캐시를 분리한다 - 로그아웃 후 다른 계정으로 로그인했을 때 이전 계정 장바구니가 잠깐 보이는 걸 막는다. */
function cartKey(accountId: string | undefined) {
  return ['cart', accountId ?? 'anonymous'];
}

/** 로그인 상태에서만 조회한다 - 토큰이 없으면 쿼리 자체를 비활성화. */
export function useCart() {
  const accessToken = useAuthStore((s) => s.accessToken);
  const accountId = useAuthStore((s) => s.account?.accountId);

  return useQuery({
    queryKey: cartKey(accountId),
    queryFn: () => fetchCart(accessToken!),
    enabled: !!accessToken,
  });
}

/** 장바구니 변경 API는 모두 갱신된 Cart 전체를 돌려주므로, 응답으로 캐시를 바로 덮어쓴다(재조회 불필요). */
function useCartMutation<TVariables>(
  mutationFn: (accessToken: string, variables: TVariables) => Promise<Cart>
) {
  const accessToken = useAuthStore((s) => s.accessToken);
  const accountId = useAuthStore((s) => s.account?.accountId);
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (variables: TVariables) => mutationFn(accessToken!, variables),
    onSuccess: (cart) => queryClient.setQueryData(cartKey(accountId), cart),
  });
}

export function useAddCartItem() {
  return useCartMutation<{ productUuid: string; quantity: number }>((token, v) =>
    addCartItem(token, v.productUuid, v.quantity)
  );
}

export function useUpdateCartItem() {
  return useCartMutation<{ cartItemId: string; quantity: number }>((token, v) =>
    updateCartItem(token, v.cartItemId, v.quantity)
  );
}

export function useRemoveCartItem() {
  return useCartMutation<{ cartItemId: string }>((token, v) => removeCartItem(token, v.cartItemId));
}
