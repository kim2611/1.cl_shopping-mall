import { StyleSheet, Text, View } from 'react-native';

import { Fonts, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export type OrderLine = {
  label: string;
  qty?: string;
  amount: string;
};

export function OrderSummary({ lines, total }: { lines: OrderLine[]; total: string }) {
  const theme = useTheme();

  return (
    <View>
      <View style={[styles.headRow, { borderColor: theme.line }]}>
        <Text style={[styles.th, { color: theme.inkFaint }]}>상품</Text>
        <Text style={[styles.th, styles.num, { color: theme.inkFaint }]}>수량</Text>
        <Text style={[styles.th, styles.num, { color: theme.inkFaint }]}>금액</Text>
      </View>
      {lines.map((line, i) => (
        <View key={i} style={[styles.row, { borderColor: theme.line }]}>
          <Text style={[styles.cell, { color: theme.ink }]} numberOfLines={1}>
            {line.label}
          </Text>
          <Text style={[styles.cell, styles.num, { color: theme.ink }]}>{line.qty ?? '—'}</Text>
          <Text style={[styles.cell, styles.num, { color: theme.ink }]}>{line.amount}</Text>
        </View>
      ))}
      <View style={styles.totalRow}>
        <Text style={[styles.totalLabel, { color: theme.ink }]}>합계</Text>
        <Text style={[styles.totalAmount, { color: theme.ink }]}>{total}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  headRow: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    paddingBottom: Spacing.sm + 2,
  },
  row: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    borderStyle: 'dashed',
    paddingVertical: Spacing.md,
  },
  th: {
    flex: 1,
    fontFamily: Fonts.mono,
    fontSize: 10.5,
    letterSpacing: 0.4,
    textTransform: 'uppercase',
  },
  cell: {
    flex: 1,
    fontFamily: Fonts.body,
    fontSize: 13.5,
  },
  num: {
    flex: 0.6,
    textAlign: 'right',
    fontVariant: ['tabular-nums'],
  },
  totalRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingTop: Spacing.md + 2,
  },
  totalLabel: {
    fontFamily: Fonts.monoBold,
    fontSize: 13.5,
  },
  totalAmount: {
    fontFamily: Fonts.monoBold,
    fontSize: 13.5,
    fontVariant: ['tabular-nums'],
  },
});
