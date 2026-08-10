import { API_BASE_URL } from '@/constants/api';

export type ProductSummary = {
  uuid: string;
  name: string;
  price: number;
  thumbnailUrl: string | null;
};

export type Paged<T> = {
  content: T[];
  page: { size: number; number: number; totalElements: number; totalPages: number };
};

export type ProductSort = 'new' | 'priceAsc' | 'priceDesc';

export type ProductDetail = {
  uuid: string;
  name: string;
  description: string | null;
  price: number;
  stockQuantity: number;
  categoryName: string | null;
  statusName: string | null;
  imageUrls: string[];
};

export async function fetchProducts(sortBy: ProductSort = 'new'): Promise<ProductSummary[]> {
  const res = await fetch(`${API_BASE_URL}/api/products?sortBy=${sortBy}&size=20`);
  if (!res.ok) {
    throw new Error(`상품 목록을 불러오지 못했습니다 (${res.status})`);
  }
  const data: Paged<ProductSummary> = await res.json();
  return data.content;
}

export async function fetchProductDetail(uuid: string): Promise<ProductDetail> {
  const res = await fetch(`${API_BASE_URL}/api/products/${uuid}`);
  if (!res.ok) {
    throw new Error(`상품 정보를 불러오지 못했습니다 (${res.status})`);
  }
  return res.json();
}

export function resolveImageUrl(path: string | null): string | null {
  if (!path) return null;
  return path.startsWith('http') ? path : `${API_BASE_URL}${path}`;
}
