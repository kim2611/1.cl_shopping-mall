import { useState } from 'react';
import { ActivityIndicator, FlatList, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { ProductCard, SortBar } from '@/components/ui';
import { Spacing } from '@/constants/theme';
import { resolveImageUrl } from '@/features/products/api';
import { useProducts } from '@/features/products/use-products';
import { useTheme } from '@/hooks/use-theme';

const SORT_OPTIONS: { key: string; label: string }[] = [
  { key: 'new', label: '신상품순' },
  { key: 'priceAsc', label: '낮은가격순' },
  { key: 'priceDesc', label: '높은가격순' },
];

export default function HomeScreen() {
  const theme = useTheme();
  const [sortBy, setSortBy] = useState<'new' | 'priceAsc' | 'priceDesc'>('new');
  const { data: products, isLoading, isError, error } = useProducts(sortBy);

  return (
    <ThemedView style={styles.flex}>
      <SafeAreaView style={styles.flex} edges={['top']}>
        <FlatList
          data={products ?? []}
          keyExtractor={(item) => item.uuid}
          numColumns={2}
          columnWrapperStyle={styles.row}
          contentContainerStyle={styles.content}
          ListHeaderComponent={
            <View style={styles.header}>
              <ThemedText variant="label" themeColor="inkFaint">
                MALL — live from backend
              </ThemedText>
              <ThemedText variant="h1" style={styles.title}>
                오늘 입고된 상품
              </ThemedText>
              <View style={styles.sortRow}>
                <SortBar options={SORT_OPTIONS} value={sortBy} onChange={(key) => setSortBy(key as typeof sortBy)} />
              </View>
              {isLoading ? <ActivityIndicator style={styles.spinner} color={theme.ink} /> : null}
              {isError ? (
                <ThemedText variant="caption" themeColor="stamp" style={styles.errorText}>
                  {error instanceof Error ? error.message : '상품을 불러오지 못했습니다.'} — 백엔드 서버가
                  켜져 있는지 확인해주세요.
                </ThemedText>
              ) : null}
            </View>
          }
          renderItem={({ item }) => (
            <ProductCard name={item.name} price={item.price} thumbnailUrl={resolveImageUrl(item.thumbnailUrl)} />
          )}
        />
      </SafeAreaView>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  content: {
    padding: Spacing.lg,
    gap: Spacing.lg,
  },
  header: {
    marginBottom: Spacing.md,
    gap: Spacing.md,
  },
  title: {
    marginTop: Spacing.xs,
  },
  sortRow: {
    marginTop: Spacing.xs,
  },
  spinner: {
    marginTop: Spacing.sm,
    alignSelf: 'flex-start',
  },
  errorText: {
    marginTop: Spacing.xs,
  },
  row: {
    gap: Spacing.lg,
  },
});
