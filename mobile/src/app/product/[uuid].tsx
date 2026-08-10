import { useLocalSearchParams } from 'expo-router';
import { ActivityIndicator, ScrollView, StyleSheet, View } from 'react-native';
import { SvgUri } from 'react-native-svg';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { Button, Tag } from '@/components/ui';
import { Radius, Spacing } from '@/constants/theme';
import { resolveImageUrl } from '@/features/products/api';
import { useProductDetail } from '@/features/products/use-product-detail';
import { useTheme } from '@/hooks/use-theme';

export default function ProductDetailScreen() {
  const { uuid } = useLocalSearchParams<{ uuid: string }>();
  const theme = useTheme();
  const { data: product, isLoading, isError, error } = useProductDetail(uuid);

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
        </View>
      </ScrollView>

      <View style={[styles.footer, { borderColor: theme.line, backgroundColor: theme.paper }]}>
        <Button label="장바구니 담기" variant="secondary" disabled={soldOut} onPress={() => {}} />
        <View style={styles.footerGap} />
        <Button label={soldOut ? '품절' : '바로구매'} variant="primary" disabled={soldOut} onPress={() => {}} />
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
