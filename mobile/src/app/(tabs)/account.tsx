import { Link } from 'expo-router';
import { Controller, useForm } from 'react-hook-form';
import { ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { Button, TextField } from '@/components/ui';
import { Spacing } from '@/constants/theme';
import { useAuthStore } from '@/features/auth/store';

type LoginForm = { email: string; password: string };

export default function AccountScreen() {
  const { account, isLoading, error, login, logout } = useAuthStore();

  if (account) {
    return (
      <ThemedView style={styles.flex}>
        <SafeAreaView style={styles.flex} edges={['top']}>
          <View style={styles.content}>
            <ThemedText variant="label" themeColor="inkFaint">
              MALL — ACCOUNT
            </ThemedText>
            <ThemedText variant="h1" style={styles.title}>
              {account.name}님
            </ThemedText>
            <ThemedText variant="body" themeColor="inkSoft" style={styles.email}>
              {account.email}
            </ThemedText>
            <View style={styles.actions}>
              <Button label="로그아웃" variant="secondary" onPress={logout} />
            </View>
          </View>
        </SafeAreaView>
      </ThemedView>
    );
  }

  return <LoginView isLoading={isLoading} error={error} onSubmit={login} />;
}

function LoginView({
  isLoading,
  error,
  onSubmit,
}: {
  isLoading: boolean;
  error: string | null;
  onSubmit: (email: string, password: string) => Promise<void>;
}) {
  const { control, handleSubmit, formState } = useForm<LoginForm>({
    defaultValues: { email: '', password: '' },
  });

  const submit = handleSubmit(async ({ email, password }) => {
    try {
      await onSubmit(email, password);
    } catch {
      // 에러 메시지는 store.error로 화면에 표시됨
    }
  });

  return (
    <ThemedView style={styles.flex}>
      <SafeAreaView style={styles.flex} edges={['top']}>
        <ScrollView contentContainerStyle={styles.content}>
          <ThemedText variant="label" themeColor="inkFaint">
            MALL — LOGIN
          </ThemedText>
          <ThemedText variant="h1" style={styles.title}>
            로그인
          </ThemedText>

          <View style={styles.form}>
            <Controller
              control={control}
              name="email"
              rules={{ required: '이메일을 입력해주세요.' }}
              render={({ field, fieldState }) => (
                <TextField
                  label="이메일"
                  placeholder="admin@mall.test"
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
              rules={{ required: '비밀번호를 입력해주세요.' }}
              render={({ field, fieldState }) => (
                <TextField
                  label="비밀번호"
                  placeholder="비밀번호"
                  secureTextEntry
                  value={field.value}
                  onChangeText={field.onChange}
                  error={fieldState.error?.message}
                />
              )}
            />
            {error ? (
              <ThemedText variant="caption" themeColor="stamp">
                {error}
              </ThemedText>
            ) : null}
            <Button
              label={isLoading ? '로그인 중...' : '로그인'}
              variant="primary"
              onPress={submit}
              disabled={isLoading || formState.isSubmitting}
            />
            <View style={styles.signupRow}>
              <ThemedText variant="caption" themeColor="inkSoft">
                계정이 없으신가요?{' '}
              </ThemedText>
              <Link href="/signup">
                <ThemedText variant="caption" style={styles.signupLink}>
                  회원가입
                </ThemedText>
              </Link>
            </View>
            <ThemedText variant="caption" themeColor="inkFaint" style={styles.hint}>
              테스트 계정: admin@mall.test / Mall!2026
            </ThemedText>
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
  email: {
    marginBottom: Spacing.xl,
  },
  actions: {
    flexDirection: 'row',
  },
  form: {
    gap: Spacing.lg,
  },
  signupRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  signupLink: {
    textDecorationLine: 'underline',
  },
  hint: {
    marginTop: Spacing.md,
  },
});
