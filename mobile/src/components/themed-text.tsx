import { StyleSheet, Text, type TextProps } from 'react-native';

import { Type, type ThemeColor } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export type ThemedTextProps = TextProps & {
  variant?: keyof typeof Type;
  themeColor?: ThemeColor;
};

export function ThemedText({ style, variant = 'body', themeColor, ...rest }: ThemedTextProps) {
  const theme = useTheme();

  return (
    <Text
      style={[{ color: theme[themeColor ?? 'ink'] }, styles[variant], style]}
      {...rest}
    />
  );
}

const styles = StyleSheet.create(Type);
