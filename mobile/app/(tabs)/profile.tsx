import { ScrollView, StyleSheet, useColorScheme } from 'react-native';

import { Card } from '@/components/Card';
import { useThemeColor } from '@/components/Themed';
import { Spacing } from '@/constants/Colors';

const TEAM = ['Ahmed', 'Max', 'Laura', 'Salman'];

export default function ProfileScreen() {
  const backgroundColor = useThemeColor({}, 'background');
  const scheme = useColorScheme() ?? 'light';

  return (
    <ScrollView
      style={{ backgroundColor }}
      contentContainerStyle={styles.content}
      contentInsetAdjustmentBehavior="automatic">
      <Card title="Team" body={TEAM.join(' · ')} />
      <Card title="Appearance" body={`Following your phone's ${scheme} mode.`} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { padding: Spacing.lg, gap: Spacing.md },
});
