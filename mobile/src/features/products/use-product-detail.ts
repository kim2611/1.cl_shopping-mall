import { useQuery } from '@tanstack/react-query';

import { fetchProductDetail } from './api';

export function useProductDetail(uuid: string) {
  return useQuery({
    queryKey: ['product', uuid],
    queryFn: () => fetchProductDetail(uuid),
    enabled: !!uuid,
  });
}
