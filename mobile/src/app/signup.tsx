import { router } from 'expo-router';
import { useState } from 'react';
import { Controller, useForm } from 'react-hook-form';
import { ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { Button, TextField } from '@/components/ui';
import { Spacing } from '@/constants/theme';
import { useAuthStore } from '@/features/auth/store';

type SignupForm = { email: string; password: string; name: string };

export default function SignupScreen() {
  const signup = useAuthStore((s) => s.signup);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const { control, handleSubmit, formState } = useForm<SignupForm>({
    defaultValues: { email: '', password: '', name: '' },
  });

  const submit = handleSubmit(async ({ email, password, name }) => {
    setSubmitError(null);
    try {
      await signup(email, password, name);
      router.replace('/account');
    } catch (e) {
      setSubmitError(e instanceof Error ? e.message : '회원가입에 실패했습니다.');
    }
  });

  return (
    <ThemedView style={styles.flex}>
      <SafeAreaView style={styles.flex} edges={['top']}>
        <ScrollView contentContainerStyle={styles.content}>
          <ThemedText variant="label" themeColor="inkFaint">
            MALL — SIGNUP
          </ThemedText>
          <ThemedText variant="h1" style={styles.title}>
            회원가입
          </ThemedText>

          <View style={styles.form}>
            <Controller
              control={control}
              name="name"
              rules={{ required: '이름을 입력해주세요.' }}
              render={({ field, fieldState }) => (
                <TextField
                  label="이름"
                  placeholder="홍길동"
                  value={field.value}
                  onChangeText={field.onChange}
                  error={fieldState.error?.message}
                />
              )}
            />
            <Controller
              control={control}
              name="email"
              rules={{
                required: '이메일을 입력해주세요.',
                pattern: { value: /^\S+@\S+\.\S+$/, message: '올바른 이메일 형식이 아닙니다.' },
              }}
              render={({ field, fieldState }) => (
                <TextField
                  label="이메일"
                  placeholder="you@example.com"
                  autoCapitalize="none"
                  keyboardType="email-address"
                  value={field.value}
                  onChangeText={field.onChange}
                  error={fieldState.error?.message}
                />
              )}
            />
            <Controller
              control={control}
              name="password"
              rules={{
                required: '비밀번호를 입력해주세요.',
                minLength: { value: 8, message: '비밀번호는 8자 이상이어야 합니다.' },
              }}
              render={({ field, fieldState }) => (
                <TextField
                  label="비밀번호 (8자 이상)"
                  placeholder="비밀번호"
                  secureTextEntry
                  value={field.value}
                  onChangeText={field.onChange}
                  error={fieldState.error?.message}
                />
              )}
            />
            {submitError ? (
              <ThemedText variant="caption" themeColor="stamp">
                {submitError}
              </ThemedText>
            ) : null}
            <Button
              label={formState.isSubmitting ? '가입 중...' : '가입하기'}
              variant="primary"
              onPress={submit}
              disabled={formState.isSubmitting}
            />
          </View>
        </ScrollView>
      </SafeAreaView>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  content: {
    padding: Spacing.xl,
    maxWidth: 480,
    width: '100%',
    alignSelf: 'center',
  },
  title: {
    marginTop: Spacing.sm,
    marginBottom: Spacing.lg,
  },
  form: {
    gap: Spacing.lg,
  },
});
