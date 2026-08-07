/**
 * MALL 디자인 토큰 — "테크팩 스펙시트" 방향 (검토용 아티팩트 rev.02 기준).
 * 색은 accent(오렌지) 1곳 + stamp(빨강, 에러/품절 전용) 1곳으로 제한한다.
 */

export const Colors = {
  light: {
    ink: '#14181C',
    inkSoft: '#5C6570',
    inkFaint: '#9BA3AC',
    paper: '#F1F4F5',
    surface: '#E6ECEC',
    line: '#C7D0D2',
    accent: '#FF4D1C',
    accentInk: '#4A1500',
    stamp: '#D62828',
    stampBg: '#FBE7E4',
  },
  dark: {
    ink: '#E7ECEC',
    inkSoft: '#A9B2B8',
    inkFaint: '#6B747A',
    paper: '#14181A',
    surface: '#1D2224',
    line: '#313A3D',
    accent: '#FF6A3D',
    accentInk: '#1A0800',
    stamp: '#FF5C5C',
    stampBg: '#2E1512',
  },
} as const;

export type ThemeColor = keyof typeof Colors.light & keyof typeof Colors.dark;

/**
 * 본문은 Pretendard(가독성), 라벨/가격/숫자는 JetBrainsMono(스펙시트 표기 느낌).
 * 실제 family 문자열은 useAppFonts()로 로드한 이름과 일치해야 한다.
 */
export const Fonts = {
  body: 'Pretendard-Regular',
  bodyMedium: 'Pretendard-Medium',
  bodySemiBold: 'Pretendard-SemiBold',
  bodyBold: 'Pretendard-Bold',
  mono: 'JetBrainsMono_400Regular',
  monoBold: 'JetBrainsMono_700Bold',
} as const;

export const Spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
  xxxl: 48,
} as const;

export const Radius = {
  sm: 2,
  md: 4,
  lg: 8,
} as const;

export const Type = {
  h1: { fontFamily: Fonts.monoBold, fontSize: 26, lineHeight: 32 },
  h2: { fontFamily: Fonts.monoBold, fontSize: 19, lineHeight: 26 },
  h3: { fontFamily: Fonts.monoBold, fontSize: 14, lineHeight: 20, letterSpacing: 0.4 },
  body: { fontFamily: Fonts.body, fontSize: 15, lineHeight: 24 },
  caption: { fontFamily: Fonts.body, fontSize: 12.5, lineHeight: 18 },
  price: { fontFamily: Fonts.monoBold, fontSize: 17, lineHeight: 22 },
  label: { fontFamily: Fonts.mono, fontSize: 11, lineHeight: 16, letterSpacing: 0.6 },
} as const;

export const MaxContentWidth = 800;
