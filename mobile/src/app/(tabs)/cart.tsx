import { router } from 'expo-router';
import { ActivityIndicator, FlatList, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { SvgUri } from 'react-native-svg';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { Button, QuantityStepper } from '@/components/ui';
import { Spacing } from '@/constants/theme';
import { useAuthStore } from '@/features/auth/store';
import type { CartItem } from '@/features/cart/api';
import { useCart, useRemoveCartItem, useUpdateCartItem } from '@/features/cart/use-cart';
import { resolveImageUrl } from '@/features/products/api';
import { useTheme } from '@/hooks/use-theme';

export default function CartScreen() {
  const theme = useTheme();
  const account = useAuthStore((s) => s.account);
  const { data: cart, isLoading, isError, error } = useCart();
  const updateItem = useUpdateCartItem();
  const removeItem = useRemoveCartItem();

  if (!account) {
    return (
      <ThemedView style={styles.flex}>
        <SafeAreaView style={[styles.flex, styles.center]} edges={['top']}>
          <ThemedText variant="body" themeColor="inkSoft" style={styles.emptyText}>
            로그인이 필요합니다.
          </ThemedText>
          <Button label="로그인하러 가기" variant="primary" onPress={() => router.push('/account')} />
        </SafeAreaView>
      </ThemedView>
    );
  }

  const mutationError = updateItem.error ?? removeItem.error;

  return (
    <ThemedView style={styles.flex}>
      <SafeAreaView style={styles.flex} edges={['top']}>
        <FlatList
          data={cart?.items ?? []}
          keyExtractor={(item) => item.cartItemId}
          contentContainerStyle={styles.content}
          ListHeaderComponent={
            <View style={styles.header}>
              <ThemedText variant="label" themeColor="inkFaint">
                MALL — CART
              </ThemedText>
              <ThemedText variant="h1" style={styles.title}>
                장바구니
              </ThemedText>
              {isLoading ? <ActivityIndicator color={theme.ink} style={styles.spinner} /> : null}
              {isError ? (
                <ThemedText variant="caption" themeColor="stamp">
                  {error instanceof Error ? error.message : '장바구니를 불러오지 못했습니다.'}
                </ThemedText>
              ) : null}
              {mutationError ? (
                <ThemedText variant="caption" themeColor="stamp">
                  {mutationError instanceof Error ? mutationError.message : '변경에 실패했습니다.'}
                </ThemedText>
              ) : null}
            </View>
          }
          ListEmptyComponent={
            !isLoading && !isError ? (
              <View style={styles.emptyBox}>
                <ThemedText variant="body" themeColor="inkSoft" style={styles.emptyText}>
                  장바구니가 비어 있습니다.
                </ThemedText>
                <Button label="상품 보러 가기" variant="secondary" onPress={() => router.push('/')} />
              </View>
            ) : null
          }
          renderItem={({ item }) => (
            <CartRow
              item={item}
              onChangeQuantity={(quantity) =>
                updateItem.mutate({ cartItemId: item.cartItemId, quantity })
              }
              onRemove={() => removeItem.mutate({ cartItemId: item.cartItemId })}
            />
          )}
        />

        {cart && cart.items.length > 0 ? (
          <View style={[styles.footer, { borderColor: theme.line, backgroundColor: theme.paper }]}>
            <View style={styles.totalRow}>
              <ThemedText variant="h3">합계 ({cart.totalQuantity}개)</ThemedText>
              <ThemedText variant="price">{cart.totalAmount.toLocaleString('ko-KR')}원</ThemedText>
            </View>
            <Button label="주문하기" variant="primary" onPress={() => router.push('/checkout')} />
          </View>
        ) : null}
      </SafeAreaView>
    </ThemedView>
  );
}

function CartRow({
  item,
  onChangeQuantity,
  onRemove,
}: {
  item: CartItem;
  onChangeQuantity: (quantity: number) => void;
  onRemove: () => void;
}) {
  const theme = useTheme();
  const thumbnail = resolveImageUrl(item.thumbnailUrl);

  return (
    <View style={[styles.row, { borderColor: theme.line }]}>
      <View style={[styles.thumb, { backgroundColor: theme.surface }]}>
        {thumbnail ? <SvgUri uri={thumbnail} width={72} height={90} /> : null}
      </View>

      <View style={styles.rowBody}>
        <ThemedText variant="body" numberOfLines={1}>
          {item.productName}
        </ThemedText>
        <ThemedText variant="price" style={styles.rowPrice}>
          {item.lineAmount.toLocaleString('ko-KR')}원
        </ThemedText>
        <ThemedText variant="caption" themeColor="inkFaint">
          개당 {item.price.toLocaleString('ko-KR')}원 · 재고 {item.stockQuantity}개
        </ThemedText>

        <View style={styles.rowActions}>
          <QuantityStepper
            value={item.quantity}
            max={item.stockQuantity}
            onChange={onChangeQuantity}
          />
          <Button label="삭제" variant="ghost" onPress={onRemove} />
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  center: { alignItems: 'center', justifyContent: 'center', gap: Spacing.lg },
  content: {
    padding: Spacing.lg,
    paddingBottom: Spacing.xxl,
  },
  header: {
    marginBottom: Spacing.lg,
    gap: Spacing.xs,
  },
  title: {
    marginTop: Spacing.xs,
  },
  spinner: {
    alignSelf: 'flex-start',
    marginTop: Spacing.sm,
  },
  emptyBox: {
    alignItems: 'center',
    gap: Spacing.lg,
    paddingVertical: Spacing.xxl,
  },
  emptyText: {
    textAlign: 'center',
  },
  row: {
    flexDirection: 'row',
    gap: Spacing.md,
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
    borderStyle: 'dashed',
  },
  thumb: {
    width: 72,
    height: 90,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rowBody: {
    flex: 1,
    gap: 4,
  },
  rowPrice: {
    marginTop: 2,
  },
  rowActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
    marginTop: Spacing.sm,
  },
  footer: {
    padding: Spacing.lg,
    borderTopWidth: 1,
    borderStyle: 'dashed',
    gap: Spacing.md,
  },
  totalRow: {
    flexDirection: 'row',
    alignItems: 'baseline',
    justifyContent: 'space-between',
  },
});
