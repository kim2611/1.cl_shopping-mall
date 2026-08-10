import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { ActivityIndicator, ScrollView, StyleSheet, View } from 'react-native';
import { SvgUri } from 'react-native-svg';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { Button, QuantityStepper, Tag } from '@/components/ui';
import { Spacing } from '@/constants/theme';
import { useAuthStore } from '@/features/auth/store';
import { useAddCartItem } from '@/features/cart/use-cart';
import { resolveImageUrl } from '@/features/products/api';
import { useProductDetail } from '@/features/products/use-product-detail';
import { useTheme } from '@/hooks/use-theme';

export default function ProductDetailScreen() {
  const { uuid } = useLocalSearchParams<{ uuid: string }>();
  const theme = useTheme();
  const { data: product, isLoading, isError, error } = useProductDetail(uuid);
  const account = useAuthStore((s) => s.account);
  const addToCart = useAddCartItem();
  const [quantity, setQuantity] = useState(1);

  if (isLoading) {
    return (
      <ThemedView style={styles.centerFlex}>
        <ActivityIndicator color={theme.ink} />
      </ThemedView>
    );
  }

  if (isError || !product) {
    return (
      <ThemedView style={[styles.centerFlex, styles.pad]}>
        <ThemedText variant="body" themeColor="stamp">
          {error instanceof Error ? error.message : '상품을 불러오지 못했습니다.'}
        </ThemedText>
      </ThemedView>
    );
  }

  const mainImage = product.imageUrls[0] ? resolveImageUrl(product.imageUrls[0]) : null;
  const soldOut = product.statusName === '품절';

  return (
    <ThemedView style={styles.flex}>
      <ScrollView>
        <View style={[styles.media, { backgroundColor: theme.surface }]}>
          {mainImage ? (
            <SvgUri uri={mainImage} width={320} height={400} />
          ) : (
            <ThemedText variant="label" themeColor="inkFaint">
              PRODUCT IMAGE
            </ThemedText>
          )}
        </View>

        <View style={styles.body}>
          {product.categoryName ? (
            <ThemedText variant="label" themeColor="inkFaint">
              {product.categoryName.toUpperCase()}
            </ThemedText>
          ) : null}
          <ThemedText variant="h1" style={styles.name}>
            {product.name}
          </ThemedText>
          <ThemedText variant="price" style={styles.price}>
            {product.price.toLocaleString('ko-KR')}원
          </ThemedText>

          <View style={styles.tagRow}>
            {soldOut ? <Tag variant="soldout">SOLD OUT</Tag> : null}
            <Tag variant="ship">{`재고 ${product.stockQuantity}개`}</Tag>
          </View>

          {product.description ? (
            <ThemedText variant="body" themeColor="inkSoft" style={styles.description}>
              {product.description}
            </ThemedText>
          ) : null}

          {!soldOut ? (
            <View style={styles.quantityRow}>
              <ThemedText variant="h3">수량</ThemedText>
              <QuantityStepper value={quantity} max={product.stockQuantity} onChange={setQuantity} />
            </View>
          ) : null}

          {addToCart.isError ? (
            <ThemedText variant="caption" themeColor="stamp" style={styles.feedback}>
              {addToCart.error instanceof Error ? addToCart.error.message : '담기에 실패했습니다.'}
            </ThemedText>
          ) : null}
          {addToCart.isSuccess ? (
            <ThemedText variant="caption" themeColor="inkSoft" style={styles.feedback}>
              장바구니에 담았습니다.
            </ThemedText>
          ) : null}
        </View>
      </ScrollView>

      <View style={[styles.footer, { borderColor: theme.line, backgroundColor: theme.paper }]}>
        <Button
          label={addToCart.isPending ? '담는 중...' : '장바구니 담기'}
          variant="secondary"
          disabled={soldOut || addToCart.isPending}
          onPress={() => {
            // 비로그인 상태면 담기 전에 로그인 화면으로 유도한다 (장바구니 API가 인증 필수라서).
            if (!account) {
              router.push('/account');
              return;
            }
            addToCart.mutate({ productUuid: product.uuid, quantity });
          }}
        />
        <View style={styles.footerGap} />
        <Button
          label={soldOut ? '품절' : '장바구니로 이동'}
          variant="primary"
          disabled={soldOut}
          onPress={() => router.push('/cart')}
        />
      </View>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  centerFlex: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  pad: { padding: Spacing.xl },
  media: {
    aspectRatio: 4 / 5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  body: {
    padding: Spacing.xl,
    gap: Spacing.sm,
  },
  name: {
    marginTop: Spacing.xs,
  },
  price: {
    marginTop: Spacing.xs,
  },
  tagRow: {
    flexDirection: 'row',
    gap: Spacing.sm,
    marginTop: Spacing.md,
  },
  description: {
    marginTop: Spacing.lg,
  },
  quantityRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: Spacing.xl,
  },
  feedback: {
    marginTop: Spacing.md,
  },
  footer: {
    flexDirection: 'row',
    padding: Spacing.lg,
    borderTopWidth: 1,
    borderStyle: 'dashed',
  },
  footerGap: {
    width: Spacing.md,
  },
});
