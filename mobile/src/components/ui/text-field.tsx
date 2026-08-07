import { useState } from 'react';
import { StyleSheet, Text, TextInput, View, type TextInputProps } from 'react-native';

import { Fonts, Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export type TextFieldProps = TextInputProps & {
  label: string;
  error?: string;
};

export function TextField({ label, error, style, onFocus, onBlur, ...rest }: TextFieldProps) {
  const theme = useTheme();
  const [focused, setFocused] = useState(false);

  const borderColor = error ? theme.stamp : focused ? theme.accent : theme.inkFaint;
  const borderStyle = error || focused ? 'solid' : 'dashed';

  return (
    <View style={styles.wrap}>
      <Text style={[styles.label, { color: theme.inkSoft }]}>{label}</Text>
      <TextInput
        style={[
          styles.input,
          { color: theme.ink, backgroundColor: theme.paper, borderColor, borderStyle },
          style,
        ]}
        placeholderTextColor={theme.inkFaint}
        onFocus={(e) => {
          setFocused(true);
          onFocus?.(e);
        }}
        onBlur={(e) => {
          setFocused(false);
          onBlur?.(e);
        }}
        {...rest}
      />
      {error ? <Text style={[styles.error, { color: theme.stamp }]}>{error}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    gap: Spacing.xs + 2,
  },
  label: {
    fontFamily: Fonts.mono,
    fontSize: 11,
    letterSpacing: 0.4,
    textTransform: 'uppercase',
  },
  input: {
    fontFamily: Fonts.body,
    fontSize: 14,
    borderWidth: 1,
    borderRadius: Radius.sm,
    paddingVertical: Spacing.md - 2,
    paddingHorizontal: Spacing.md,
  },
  error: {
    fontFamily: Fonts.mono,
    fontSize: 11,
  },
});
