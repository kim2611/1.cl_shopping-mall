import { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import {
  Button,
  OrderSummary,
  ProductCard,
  SortBar,
  Table,
  Tag,
  TextField,
  type SortOption,
  type TableColumn,
} from '@/components/ui';
import { Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

const SORT_OPTIONS: SortOption[] = [
  { key: 'popular', label: '인기순' },
  { key: 'new', label: '신상품순' },
  { key: 'priceAsc', label: '낮은가격순' },
  { key: 'priceDesc', label: '높은가격순' },
];

type OrderRow = { orderNo: string; date: string; status: string; amount: string };

const ORDER_ROWS: OrderRow[] = [
  { orderNo: 'ORD-20260805-01', date: '08.05', status: '배송중', amount: '39,000원' },
  { orderNo: 'ORD-20260802-03', date: '08.02', status: '배송완료', amount: '104,000원' },
  { orderNo: 'ORD-20260728-02', date: '07.28', status: '취소', amount: '28,000원' },
];

const ORDER_COLUMNS: TableColumn<OrderRow>[] = [
  { key: 'orderNo', label: '주문번호', flex: 1.6 },
  { key: 'date', label: '날짜' },
  { key: 'status', label: '상태' },
  { key: 'amount', label: '금액', align: 'right' },
];

function Section({ label, children }: { label: string; children: React.ReactNode }) {
  const theme = useTheme();
  return (
    <View style={styles.section}>
      <View style={styles.sectionHead}>
        <ThemedText variant="label" themeColor="inkFaint">
          {label}
        </ThemedText>
        <View style={[styles.rule, { borderColor: theme.line }]} />
      </View>
      {children}
    </View>
  );
}

export default function StyleGuideScreen() {
  const theme = useTheme();
  const [sort, setSort] = useState(SORT_OPTIONS[0].key);

  return (
    <ThemedView style={styles.flex}>
      <ScrollView contentContainerStyle={styles.content}>
        <ThemedText variant="label" themeColor="inkFaint">
          MALL — TECH PACK / VISUAL SPEC
        </ThemedText>
        <ThemedText variant="h1" style={styles.title}>
          컴포넌트 스펙
        </ThemedText>
        <ThemedText variant="body" themeColor="inkSoft" style={styles.lede}>
          토큰이 실제 컴포넌트에 적용된 모습입니다. 색은 accent(오렌지) 1곳, stamp(빨강)는 에러·품절
          전용입니다.
        </ThemedText>

        <Section label="button / spec-03">
          <View style={styles.row}>
            <Button label="바로구매" variant="primary" />
            <Button label="장바구니 담기" variant="secondary" />
            <Button label="찜하기" variant="ghost" />
            <Button label="품절된 옵션" variant="secondary" disabled />
          </View>
        </Section>

        <Section label="input / spec-04">
          <View style={styles.fieldGrid}>
            <View style={styles.fieldItem}>
              <TextField label="수령인" placeholder="이름을 입력하세요" />
            </View>
            <View style={styles.fieldItem}>
              <TextField label="연락처" defaultValue="010-123" error="전화번호 형식을 확인해주세요." />
            </View>
          </View>
        </Section>

        <Section label="tag / spec-05">
          <View style={styles.row}>
            <Tag variant="new">NEW</Tag>
            <Tag variant="sale">-30%</Tag>
            <Tag variant="soldout">SOLD OUT</Tag>
            <Tag variant="ship">무료배송</Tag>
          </View>
        </Section>

        <Section label="card / spec-06">
          <View style={styles.row}>
            <ProductCard name="오버사이즈 코튼 셔츠" price={39000} tag="new" tagLabel="NEW" freeShipping />
            <ProductCard name="와이드 팬츠" price={52000} tag="sale" tagLabel="-20%" />
          </View>
        </Section>

        <Section label="order docket / spec-07">
          <OrderSummary
            lines={[
              { label: '오버사이즈 코튼 셔츠 (M)', qty: '1', amount: '39,000원' },
              { label: '와이드 팬츠 (L)', qty: '2', amount: '104,000원' },
              { label: '배송비', qty: '—', amount: '0원' },
            ]}
            total="143,000원"
          />
        </Section>

        <Section label="sort / spec-08">
          <SortBar options={SORT_OPTIONS} value={sort} onChange={setSort} />
        </Section>

        <Section label="table / spec-09">
          <Table columns={ORDER_COLUMNS} rows={ORDER_ROWS} />
        </Section>
      </ScrollView>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  content: {
    padding: Spacing.xl,
    paddingBottom: Spacing.xxxl,
    gap: 0,
    maxWidth: 640,
    width: '100%',
    alignSelf: 'center',
  },
  title: {
    marginTop: Spacing.sm,
    marginBottom: Spacing.sm,
  },
  lede: {
    maxWidth: 480,
  },
  section: {
    marginTop: Spacing.xxl,
  },
  sectionHead: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
    marginBottom: Spacing.lg,
  },
  rule: {
    flex: 1,
    borderTopWidth: 1,
    borderStyle: 'dashed',
  },
  row: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.md,
  },
  fieldGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.lg,
  },
  fieldItem: {
    flexGrow: 1,
    minWidth: 200,
  },
});
