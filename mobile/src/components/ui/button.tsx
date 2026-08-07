import { Pressable, StyleSheet, Text, type PressableProps } from 'react-native';

import { Fonts, Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export type ButtonVariant = 'primary' | 'secondary' | 'ghost';

export type ButtonProps = Omit<PressableProps, 'style'> & {
  label: string;
  variant?: ButtonVariant;
};

export function Button({ label, variant = 'primary', disabled, ...rest }: ButtonProps) {
  const theme = useTheme();

  const variantStyle = disabled
    ? { backgroundColor: theme.surface, borderColor: theme.line, borderStyle: 'dashed' as const }
    : variant === 'primary'
      ? { backgroundColor: theme.accent, borderColor: theme.accent, borderStyle: 'solid' as const }
      : variant === 'secondary'
        ? { backgroundColor: 'transparent', borderColor: theme.ink, borderStyle: 'dashed' as const }
        : { backgroundColor: 'transparent', borderColor: 'transparent', borderStyle: 'solid' as const };

  const textColor = disabled
    ? theme.inkFaint
    : variant === 'primary'
      ? theme.accentInk
      : variant === 'secondary'
        ? theme.ink
        : theme.inkSoft;

  return (
    <Pressable
      disabled={disabled}
      style={({ pressed }) => [
        styles.base,
        variantStyle,
        variant === 'ghost' && styles.ghostPadding,
        pressed && !disabled && styles.pressed,
      ]}
      {...rest}>
      <Text
        style={[
          styles.label,
          { color: textColor },
          variant === 'ghost' && styles.underline,
        ]}>
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    borderWidth: 1,
    borderRadius: Radius.sm,
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.xl,
    alignItems: 'center',
    justifyContent: 'center',
  },
  ghostPadding: {
    paddingHorizontal: Spacing.xs,
  },
  pressed: {
    opacity: 0.7,
  },
  label: {
    fontFamily: Fonts.monoBold,
    fontSize: 12.5,
    letterSpacing: 0.4,
    textTransform: 'uppercase',
  },
  underline: {
    textDecorationLine: 'underline',
  },
});
