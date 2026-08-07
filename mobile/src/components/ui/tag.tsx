import { StyleSheet, Text, View } from 'react-native';

import { Fonts, Radius } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export type TagVariant = 'new' | 'sale' | 'soldout' | 'ship';

export function Tag({ variant, children }: { variant: TagVariant; children: string }) {
  const theme = useTheme();

  if (variant === 'new') {
    return (
      <View style={[styles.base, { backgroundColor: theme.accent }]}>
        <Text style={[styles.text, { color: theme.accentInk }]}>{children}</Text>
      </View>
    );
  }
  if (variant === 'sale') {
    return (
      <View style={[styles.base, styles.sale, { borderColor: theme.stamp }]}>
        <Text style={[styles.text, { color: theme.stamp }]}>{children}</Text>
      </View>
    );
  }
  if (variant === 'soldout') {
    return (
      <View style={[styles.base, { backgroundColor: theme.surface }]}>
        <Text style={[styles.text, styles.strike, { color: theme.inkFaint }]}>{children}</Text>
      </View>
    );
  }
  return (
    <View style={[styles.base, styles.dashed, { borderColor: theme.line }]}>
      <Text style={[styles.text, { color: theme.inkSoft }]}>{children}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  base: {
    borderRadius: Radius.sm,
    paddingVertical: 5,
    paddingHorizontal: 9,
    alignSelf: 'flex-start',
  },
  dashed: {
    borderWidth: 1,
    borderStyle: 'dashed',
  },
  sale: {
    borderWidth: 1.5,
    transform: [{ rotate: '-3deg' }],
  },
  text: {
    fontFamily: Fonts.mono,
    fontSize: 11,
    letterSpacing: 0.4,
    textTransform: 'uppercase',
  },
  strike: {
    textDecorationLine: 'line-through',
  },
});
