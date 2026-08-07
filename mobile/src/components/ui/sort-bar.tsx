import { ScrollView, StyleSheet, Text, TouchableOpacity } from 'react-native';

import { Fonts, Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export type SortOption = { key: string; label: string };

export type SortBarProps = {
  options: SortOption[];
  value: string;
  onChange: (key: string) => void;
};

export function SortBar({ options, value, onChange }: SortBarProps) {
  const theme = useTheme();

  return (
    <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.row}>
      {options.map((option) => {
        const selected = option.key === value;
        return (
          <TouchableOpacity
            key={option.key}
            onPress={() => onChange(option.key)}
            style={[
              styles.pill,
              selected
                ? { backgroundColor: theme.accent, borderColor: theme.accent, borderStyle: 'solid' }
                : { backgroundColor: 'transparent', borderColor: theme.line, borderStyle: 'dashed' },
            ]}>
            <Text
              style={[
                styles.label,
                { color: selected ? theme.accentInk : theme.inkSoft },
                selected && styles.labelSelected,
              ]}>
              {option.label}
            </Text>
          </TouchableOpacity>
        );
      })}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    gap: Spacing.sm,
  },
  pill: {
    borderWidth: 1,
    borderRadius: Radius.sm,
    paddingVertical: Spacing.sm,
    paddingHorizontal: Spacing.md,
  },
  label: {
    fontFamily: Fonts.mono,
    fontSize: 12,
  },
  labelSelected: {
    fontFamily: Fonts.monoBold,
  },
});
