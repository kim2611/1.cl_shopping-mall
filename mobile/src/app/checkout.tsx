import { router } from 'expo-router';
import { useState } from 'react';
import { Controller, useForm } from 'react-hook-form';
import { ScrollView, StyleSheet, View } from 'react-native';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { Button, OrderSummary, TextField } from '@/components/ui';
import { Spacing } from '@/constants/theme';
import { useCart } from '@/features/cart/use-cart';
import { useCreateOrder } from '@/features/orders/use-orders';
import { useTheme } from '@/hooks/use-theme';

type CheckoutForm = {
  recipientName: string;
  phone: string;
  zipCode: string;
  address1: string;
  address2: string;
};

export default function CheckoutScreen() {
  const theme = useTheme();
  const { data: cart } = useCart();
  // 주문서 화면에 들어올 때 한 번만 만든다 - 같은 화면에서 재시도하면 같은 키라 주문이 중복 생성되지 않고,
  // 주문서에 새로 들어오면 새 키가 되어 새 주문이 정상적으로 만들어진다.
  const [idempotencyKey] = useState(
    () => `checkout-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`
  );
  const createOrder = useCreateOrder(idempotencyKey);
  const { control, handleSubmit, formState } = useForm<CheckoutForm>({
    defaultValues: { recipientName: '', phone: '', zipCode: '', address1: '', address2: '' },
  });

  const submit = handleSubmit(async (form) => {
    const order = await createOrder.mutateAsync(form);
    // 뒤로가기로 결제 화면에 다시 오면 안 되므로 replace로 주문 완료 화면으로 넘긴다.
    router.replace(`/order/${order.orderNumber}`);
  });

  if (!cart || cart.items.length === 0) {
    return (
      <ThemedView style={[styles.flex, styles.center]}>
        <ThemedText variant="body" themeColor="inkSoft">
          주문할 상품이 없습니다.
        </ThemedText>
      </ThemedView>
    );
  }

  return (
    <ThemedView style={styles.flex}>
      <ScrollView contentContainerStyle={styles.content}>
        <ThemedText variant="label" themeColor="inkFaint">
          MALL — CHECKOUT
        </ThemedText>
        <ThemedText variant="h1" style={styles.title}>
          주문서
        </ThemedText>

        <ThemedText variant="h3" style={styles.sectionTitle}>
          배송지
        </ThemedText>
        <View style={styles.form}>
          <Controller
            control={control}
            name="recipientName"
            rules={{ required: '수령인을 입력해주세요.' }}
            render={({ field, fieldState }) => (
              <TextField
                label="수령인"
                placeholder="홍길동"
                value={field.value}
                onChangeText={field.onChange}
                error={fieldState.error?.message}
              />
            )}
          />
          <Controller
            control={control}
            name="phone"
            rules={{ required: '연락처를 입력해주세요.' }}
            render={({ field, fieldState }) => (
              <TextField
                label="연락처"
                placeholder="010-0000-0000"
                keyboardType="phone-pad"
                value={field.value}
                onChangeText={field.onChange}
                error={fieldState.error?.message}
              />
            )}
          />
          <Controller
            control={control}
            name="zipCode"
            rules={{ required: '우편번호를 입력해주세요.' }}
            render={({ field, fieldState }) => (
              <TextField
                label="우편번호"
                placeholder="06236"
                keyboardType="number-pad"
                value={field.value}
                onChangeText={field.onChange}
                error={fieldState.error?.message}
              />
            )}
          />
          <Controller
            control={control}
            name="address1"
            rules={{ required: '주소를 입력해주세요.' }}
            render={({ field, fieldState }) => (
              <TextField
                label="주소"
                placeholder="서울시 강남구 테헤란로 1"
                value={field.value}
                onChangeText={field.onChange}
                error={fieldState.error?.message}
              />
            )}
          />
          <Controller
            control={control}
            name="address2"
            render={({ field }) => (
              <TextField
                label="상세주소 (선택)"
                placeholder="5층 501호"
                value={field.value}
                onChangeText={field.onChange}
              />
            )}
          />
        </View>

        <ThemedText variant="h3" style={styles.sectionTitle}>
          주문 상품
        </ThemedText>
        <OrderSummary
          lines={cart.items.map((item) => ({
            label: item.productName,
            qty: String(item.quantity),
            amount: `${item.lineAmount.toLocaleString('ko-KR')}원`,
          }))}
          total={`${cart.totalAmount.toLocaleString('ko-KR')}원`}
        />
        <ThemedText variant="caption" themeColor="inkFaint" style={styles.note}>
          배송비는 회사별 정책에 따라 주문 확정 시 계산됩니다 (3만원 이상 무료배송).
        </ThemedText>

        {createOrder.isError ? (
          <ThemedText variant="caption" themeColor="stamp" style={styles.note}>
            {createOrder.error instanceof Error ? createOrder.error.message : '주문에 실패했습니다.'}
          </ThemedText>
        ) : null}
      </ScrollView>

      <View style={[styles.footer, { borderColor: theme.line, backgroundColor: theme.paper }]}>
        <Button
          label={createOrder.isPending ? '주문 처리 중...' : '결제하고 주문하기'}
          variant="primary"
          disabled={createOrder.isPending || formState.isSubmitting}
          onPress={submit}
        />
      </View>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  center: { alignItems: 'center', justifyContent: 'center' },
  content: {
    padding: Spacing.xl,
    paddingBottom: Spacing.xxl,
    maxWidth: 560,
    width: '100%',
    alignSelf: 'center',
  },
  title: { marginTop: Spacing.sm },
  sectionTitle: { marginTop: Spacing.xxl, marginBottom: Spacing.md },
  form: { gap: Spacing.lg },
  note: { marginTop: Spacing.md },
  footer: {
    padding: Spacing.lg,
    borderTopWidth: 1,
    borderStyle: 'dashed',
  },
});
