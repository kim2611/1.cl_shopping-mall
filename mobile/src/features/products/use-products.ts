import { useQuery } from '@tanstack/react-query';

import { fetchProducts, type ProductSort } from './api';

export function useProducts(sortBy: ProductSort = 'new') {
  return useQuery({
    queryKey: ['products', sortBy],
    queryFn: () => fetchProducts(sortBy),
  });
}
