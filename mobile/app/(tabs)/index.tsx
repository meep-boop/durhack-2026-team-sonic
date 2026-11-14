import Constants from 'expo-constants';
import { ScrollView, StyleSheet } from 'react-native';

import { Card } from '@/components/Card';
import { Text, useThemeColor } from '@/components/Themed';
import { Spacing } from '@/constants/Colors';

export default function HomeScreen() {
  const backgroundColor = useThemeColor({}, 'background');
  const mutedText = useThemeColor({}, 'mutedText');
  const tint = useThemeColor({}, 'tint');

  return (
    <ScrollView
      style={{ backgroundColor }}
      contentContainerStyle={styles.content}
      contentInsetAdjustmentBehavior="automatic">
      <Text style={[styles.eyebrow, { color: tint }]}>DURHACK 2026</Text>
      <Text style={styles.title}>Team Sonic</Text>
      <Text style={[styles.subtitle, { color: mutedText }]}>
        Our idea is coming soon. This is the mobile shell we'll build it on.
      </Text>

      <Card
        title="It runs on your phone"
        body="You're looking at it in Expo Go. Every change we save reloads here live."
      />
      <Card title="What's next" body="Once the team picks the idea, its screens land in these tabs." />

      <Text style={[styles.version, { color: mutedText }]}>
        v{Constants.expoConfig?.version ?? '1.0.0'}
      </Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { padding: Spacing.lg, gap: Spacing.md },
  eyebrow: { fontSize: 13, fontWeight: '700', letterSpacing: 1.2 },
  title: { fontSize: 34, fontWeight: '800' },
  subtitle: { fontSize: 17, lineHeight: 24, marginBottom: Spacing.sm },
  version: { fontSize: 13, textAlign: 'center', marginTop: Spacing.lg },
});
