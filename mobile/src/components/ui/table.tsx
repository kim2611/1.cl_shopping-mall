import { StyleSheet, Text, View } from 'react-native';

import { Fonts, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export type TableColumn<T> = {
  key: keyof T;
  label: string;
  align?: 'left' | 'right';
  flex?: number;
};

export function Table<T extends Record<string, string>>({
  columns,
  rows,
}: {
  columns: TableColumn<T>[];
  rows: T[];
}) {
  const theme = useTheme();

  return (
    <View>
      <View style={[styles.headRow, { borderColor: theme.line }]}>
        {columns.map((col) => (
          <Text
            key={String(col.key)}
            style={[
              styles.th,
              { flex: col.flex ?? 1, color: theme.inkFaint, textAlign: col.align ?? 'left' },
            ]}>
            {col.label}
          </Text>
        ))}
      </View>
      {rows.map((row, i) => (
        <View key={i} style={[styles.row, { borderColor: theme.line }]}>
          {columns.map((col) => (
            <Text
              key={String(col.key)}
              numberOfLines={1}
              style={[
                styles.cell,
                col.align === 'right' && styles.num,
                { flex: col.flex ?? 1, color: theme.ink, textAlign: col.align ?? 'left' },
              ]}>
              {row[col.key]}
            </Text>
          ))}
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  headRow: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    paddingBottom: Spacing.sm + 2,
    gap: Spacing.sm,
  },
  row: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    borderStyle: 'dashed',
    paddingVertical: Spacing.md,
    gap: Spacing.sm,
  },
  th: {
    fontFamily: Fonts.mono,
    fontSize: 10.5,
    letterSpacing: 0.4,
    textTransform: 'uppercase',
  },
  cell: {
    fontFamily: Fonts.body,
    fontSize: 13,
  },
  num: {
    fontFamily: Fonts.mono,
    fontVariant: ['tabular-nums'],
  },
});
