import { FlatList, StyleSheet } from 'react-native';

import { Card } from '@/components/Card';
import { useThemeColor } from '@/components/Themed';
import { Spacing } from '@/constants/Colors';

// Placeholder rows until the idea is picked; swap for real data then.
const ITEMS = [
  { id: '1', title: 'Feature one', body: 'Placeholder: the first thing our app will do.' },
  { id: '2', title: 'Feature two', body: 'Placeholder: a second screen or flow.' },
  { id: '3', title: 'Feature three', body: 'Placeholder: something to demo to the judges.' },
];

export default function ExploreScreen() {
  const backgroundColor = useThemeColor({}, 'background');

  return (
    <FlatList
      style={{ backgroundColor }}
      contentContainerStyle={styles.content}
      contentInsetAdjustmentBehavior="automatic"
      data={ITEMS}
      keyExtractor={(item) => item.id}
      renderItem={({ item }) => <Card title={item.title} body={item.body} />}
    />
  );
}

const styles = StyleSheet.create({
  content: { padding: Spacing.lg, gap: Spacing.md },
});
