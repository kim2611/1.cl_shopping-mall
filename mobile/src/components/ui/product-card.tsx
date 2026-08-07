import { StyleSheet, Text, View } from 'react-native';
import { SvgUri } from 'react-native-svg';

import { Fonts, Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { Tag, type TagVariant } from './tag';

const CARD_WIDTH = 168;
const CARD_MEDIA_HEIGHT = (CARD_WIDTH * 5) / 4;

export type ProductCardProps = {
  name: string;
  price: number;
  thumbnailUrl?: string | null;
  tag?: TagVariant;
  tagLabel?: string;
  freeShipping?: boolean;
};

export function ProductCard({ name, price, thumbnailUrl, tag, tagLabel, freeShipping }: ProductCardProps) {
  const theme = useTheme();

  return (
    <View style={[styles.card, { borderColor: theme.line }]}>
      <View style={[styles.media, { backgroundColor: theme.surface }]}>
        {thumbnailUrl ? (
          // 시드 상품 이미지가 전부 SVG라 SvgUri로 렌더링한다 (RN의 기본 Image는 SVG를 못 그림).
          <SvgUri uri={thumbnailUrl} width={CARD_WIDTH} height={CARD_MEDIA_HEIGHT} />
        ) : (
          <Text style={[styles.mediaMark, { color: theme.inkFaint }]}>PRODUCT IMAGE</Text>
        )}
      </View>
      <View style={[styles.body, { borderColor: theme.line }]}>
        {tag ? (
          <View style={styles.tagRow}>
            <Tag variant={tag}>{tagLabel ?? tag.toUpperCase()}</Tag>
          </View>
        ) : null}
        <Text style={[styles.name, { color: theme.ink }]} numberOfLines={1}>
          {name}
        </Text>
        <Text style={[styles.price, { color: theme.ink }]}>
          {price.toLocaleString('ko-KR')}원
          {freeShipping ? <Text style={[styles.note, { color: theme.inkFaint }]}> 무료배송</Text> : null}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    width: CARD_WIDTH,
    borderWidth: 1,
    borderRadius: Radius.sm,
    overflow: 'hidden',
  },
  media: {
    aspectRatio: 4 / 5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  mediaMark: {
    fontFamily: Fonts.mono,
    fontSize: 9,
    letterSpacing: 0.4,
  },
  body: {
    padding: Spacing.md,
    gap: 6,
    borderTopWidth: 1,
    borderStyle: 'dashed',
  },
  tagRow: {
    flexDirection: 'row',
  },
  name: {
    fontFamily: Fonts.body,
    fontSize: 13.5,
  },
  price: {
    fontFamily: Fonts.monoBold,
    fontSize: 14.5,
  },
  note: {
    fontFamily: Fonts.body,
    fontSize: 11,
  },
});
