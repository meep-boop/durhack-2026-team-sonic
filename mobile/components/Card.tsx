import { StyleSheet } from 'react-native';

import { Text, View, useThemeColor } from '@/components/Themed';
import { Radius, Spacing } from '@/constants/Colors';

type CardProps = { title: string; body: string };

export function Card({ title, body }: CardProps) {
  const backgroundColor = useThemeColor({}, 'card');
  const borderColor = useThemeColor({}, 'border');
  const mutedText = useThemeColor({}, 'mutedText');

  return (
    <View style={[styles.card, { backgroundColor, borderColor }]}>
      <Text style={styles.title}>{title}</Text>
      <Text style={[styles.body, { color: mutedText }]}>{body}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderRadius: Radius.lg,
    borderWidth: StyleSheet.hairlineWidth,
    padding: Spacing.md,
    gap: Spacing.xs,
  },
  title: { fontSize: 17, fontWeight: '600' },
  body: { fontSize: 15, lineHeight: 21 },
});
