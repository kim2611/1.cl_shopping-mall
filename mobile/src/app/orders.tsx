import { router } from 'expo-router';
import { ActivityIndicator, FlatList, Pressable, StyleSheet, View } from 'react-native';
import { SvgUri } from 'react-native-svg';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { Button, Tag } from '@/components/ui';
import { Spacing } from '@/constants/theme';
import { useOrders } from '@/features/orders/use-orders';
import { resolveImageUrl } from '@/features/products/api';
import { useTheme } from '@/hooks/use-theme';

export default function OrdersScreen() {
  const theme = useTheme();
  const { data: orders, isLoading, isError, error } = useOrders();

  return (
    <ThemedView style={styles.flex}>
      <FlatList
        data={orders ?? []}
        keyExtractor={(item) => item.orderNumber}
        contentContainerStyle={styles.content}
        ListHeaderComponent={
          <View style={styles.header}>
            <ThemedText variant="label" themeColor="inkFaint">
              MALL — ORDER HISTORY
            </ThemedText>
            <ThemedText variant="h1" style={styles.title}>
              주문 내역
            </ThemedText>
            {isLoading ? <ActivityIndicator color={theme.ink} style={styles.spinner} /> : null}
            {isError ? (
              <ThemedText variant="caption" themeColor="stamp">
                {error instanceof Error ? error.message : '주문 내역을 불러오지 못했습니다.'}
              </ThemedText>
            ) : null}
          </View>
        }
        ListEmptyComponent={
          !isLoading && !isError ? (
            <View style={styles.emptyBox}>
              <ThemedText variant="body" themeColor="inkSoft">
                주문 내역이 없습니다.
              </ThemedText>
              <Button label="상품 보러 가기" variant="secondary" onPress={() => router.replace('/')} />
            </View>
          ) : null
        }
        renderItem={({ item }) => {
          const thumbnail = resolveImageUrl(item.thumbnailUrl);
          return (
            <Pressable onPress={() => router.push(`/order/${item.orderNumber}`)}>
              <View style={[styles.row, { borderColor: theme.line }]}>
                <View style={[styles.thumb, { backgroundColor: theme.surface }]}>
                  {thumbnail ? <SvgUri uri={thumbnail} width={64} height={80} /> : null}
                </View>
                <View style={styles.rowBody}>
                  <View style={styles.rowTop}>
                    <ThemedText variant="label" themeColor="inkFaint">
                      {item.orderNumber}
                    </ThemedText>
                    <Tag variant="ship">{item.statusName}</Tag>
                  </View>
                  <ThemedText variant="body" numberOfLines={1}>
                    {item.representativeProductName}
                    {item.itemCount > 1 ? ` 외 ${item.itemCount - 1}건` : ''}
                  </ThemedText>
                  <ThemedText variant="price">
                    {item.totalAmount.toLocaleString('ko-KR')}원
                  </ThemedText>
                  <ThemedText variant="caption" themeColor="inkFaint">
                    {new Date(item.orderedAt).toLocaleDateString('ko-KR')}
                  </ThemedText>
                </View>
              </View>
            </Pressable>
          );
        }}
      />
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  content: {
    padding: Spacing.lg,
    paddingBottom: Spacing.xxl,
    maxWidth: 560,
    width: '100%',
    alignSelf: 'center',
  },
  header: { marginBottom: Spacing.lg, gap: Spacing.xs },
  title: { marginTop: Spacing.xs },
  spinner: { alignSelf: 'flex-start', marginTop: Spacing.sm },
  emptyBox: { alignItems: 'center', gap: Spacing.lg, paddingVertical: Spacing.xxl },
  row: {
    flexDirection: 'row',
    gap: Spacing.md,
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
    borderStyle: 'dashed',
  },
  thumb: { width: 64, height: 80, alignItems: 'center', justifyContent: 'center' },
  rowBody: { flex: 1, gap: 4 },
  rowTop: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: Spacing.sm },
});
