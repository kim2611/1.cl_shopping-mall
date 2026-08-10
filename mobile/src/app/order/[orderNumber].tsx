import { router, useLocalSearchParams } from 'expo-router';
import { ActivityIndicator, ScrollView, StyleSheet, View } from 'react-native';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { Button, OrderSummary, Tag } from '@/components/ui';
import { Spacing } from '@/constants/theme';
import { useOrder } from '@/features/orders/use-orders';
import { useTheme } from '@/hooks/use-theme';

export default function OrderDetailScreen() {
  const { orderNumber } = useLocalSearchParams<{ orderNumber: string }>();
  const theme = useTheme();
  const { data: order, isLoading, isError, error } = useOrder(orderNumber);

  if (isLoading) {
    return (
      <ThemedView style={[styles.flex, styles.center]}>
        <ActivityIndicator color={theme.ink} />
      </ThemedView>
    );
  }

  if (isError || !order) {
    return (
      <ThemedView style={[styles.flex, styles.center, styles.pad]}>
        <ThemedText variant="body" themeColor="stamp">
          {error instanceof Error ? error.message : '주문을 불러오지 못했습니다.'}
        </ThemedText>
      </ThemedView>
    );
  }

  return (
    <ThemedView style={styles.flex}>
      <ScrollView contentContainerStyle={styles.content}>
        <ThemedText variant="label" themeColor="inkFaint">
          MALL — ORDER {order.orderNumber}
        </ThemedText>
        <ThemedText variant="h1" style={styles.title}>
          주문이 완료되었습니다
        </ThemedText>

        <View style={styles.tagRow}>
          <Tag variant="new">{order.statusName}</Tag>
          {order.paymentStatusName ? (
            <Tag variant="ship">{`결제 ${order.paymentStatusName}`}</Tag>
          ) : null}
        </View>

        <ThemedText variant="h3" style={styles.sectionTitle}>
          주문 상품
        </ThemedText>
        <OrderSummary
          lines={[
            ...order.items.map((item) => ({
              label: item.productName,
              qty: String(item.quantity),
              amount: `${item.lineAmount.toLocaleString('ko-KR')}원`,
            })),
            {
              label: '배송비',
              qty: '—',
              amount: `${order.deliveryFee.toLocaleString('ko-KR')}원`,
            },
          ]}
          total={`${order.totalAmount.toLocaleString('ko-KR')}원`}
        />

        <ThemedText variant="h3" style={styles.sectionTitle}>
          배송지
        </ThemedText>
        <View style={[styles.infoBox, { borderColor: theme.line }]}>
          <ThemedText variant="body">{order.recipientName}</ThemedText>
          <ThemedText variant="caption" themeColor="inkSoft">
            {order.phone}
          </ThemedText>
          <ThemedText variant="caption" themeColor="inkSoft">
            ({order.zipCode}) {order.address1} {order.address2 ?? ''}
          </ThemedText>
        </View>

        <ThemedText variant="caption" themeColor="inkFaint" style={styles.note}>
          결제수단: {order.paymentMethodName ?? '-'}
        </ThemedText>
      </ScrollView>

      <View style={[styles.footer, { borderColor: theme.line, backgroundColor: theme.paper }]}>
        <Button label="주문 내역 보기" variant="secondary" onPress={() => router.replace('/orders')} />
        <View style={styles.footerGap} />
        <Button label="쇼핑 계속하기" variant="primary" onPress={() => router.replace('/')} />
      </View>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  center: { alignItems: 'center', justifyContent: 'center' },
  pad: { padding: Spacing.xl },
  content: {
    padding: Spacing.xl,
    paddingBottom: Spacing.xxl,
    maxWidth: 560,
    width: '100%',
    alignSelf: 'center',
  },
  title: { marginTop: Spacing.sm },
  tagRow: { flexDirection: 'row', gap: Spacing.sm, marginTop: Spacing.lg },
  sectionTitle: { marginTop: Spacing.xxl, marginBottom: Spacing.md },
  infoBox: {
    borderWidth: 1,
    borderStyle: 'dashed',
    padding: Spacing.lg,
    gap: 4,
  },
  note: { marginTop: Spacing.lg },
  footer: {
    flexDirection: 'row',
    padding: Spacing.lg,
    borderTopWidth: 1,
    borderStyle: 'dashed',
  },
  footerGap: { width: Spacing.md },
});
