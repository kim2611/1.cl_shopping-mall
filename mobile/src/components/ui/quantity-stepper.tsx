import { Pressable, StyleSheet, Text, View } from 'react-native';

import { Fonts, Radius } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export type QuantityStepperProps = {
  value: number;
  onChange: (next: number) => void;
  min?: number;
  max?: number;
  disabled?: boolean;
};

export function QuantityStepper({ value, onChange, min = 1, max = 99, disabled }: QuantityStepperProps) {
  const theme = useTheme();

  const canDecrease = !disabled && value > min;
  const canIncrease = !disabled && value < max;

  return (
    <View style={[styles.row, { borderColor: theme.line }]}>
      <StepButton label="−" enabled={canDecrease} onPress={() => onChange(value - 1)} />
      <Text style={[styles.value, { color: theme.ink, borderColor: theme.line }]}>{value}</Text>
      <StepButton label="+" enabled={canIncrease} onPress={() => onChange(value + 1)} />
    </View>
  );
}

function StepButton({
  label,
  enabled,
  onPress,
}: {
  label: string;
  enabled: boolean;
  onPress: () => void;
}) {
  const theme = useTheme();
  return (
    <Pressable
      disabled={!enabled}
      onPress={onPress}
      style={({ pressed }) => [styles.button, pressed && enabled && styles.pressed]}>
      <Text style={[styles.buttonLabel, { color: enabled ? theme.ink : theme.inkFaint }]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'stretch',
    borderWidth: 1,
    borderRadius: Radius.sm,
    alignSelf: 'flex-start',
  },
  button: {
    width: 34,
    height: 32,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pressed: {
    opacity: 0.5,
  },
  buttonLabel: {
    fontFamily: Fonts.mono,
    fontSize: 15,
  },
  value: {
    minWidth: 36,
    textAlign: 'center',
    lineHeight: 32,
    fontFamily: Fonts.monoBold,
    fontSize: 13,
    borderLeftWidth: 1,
    borderRightWidth: 1,
    fontVariant: ['tabular-nums'],
  },
});
