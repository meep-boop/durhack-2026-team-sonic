import { useAssets } from 'expo-asset';
import { useRef, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { Card } from '@/components/Card';
import { Text, useThemeColor } from '@/components/Themed';
import { Radius, Spacing } from '@/constants/Colors';
import { SonicArView, hasLidar, isArAvailable, type ArMode, type SonicArViewRef } from '@/modules/sonic-ar';

// Width of the marker as you show it (printed, or on a laptop screen). Tracking scale is only as right as this number.
const MARKER_WIDTH_M = 0.15;

const MODES: { key: ArMode; label: string; hint: string }[] = [
  { key: 'place', label: 'Place', hint: 'Move your phone to find a surface, then tap to drop a cube. Drag, pinch or twist it.' },
  { key: 'image', label: 'Image', hint: 'Point the camera at the Team Sonic marker (mobile/assets/ar/marker.png).' },
  { key: 'measure', label: 'Measure', hint: hasLidar ? 'Tap two points. LiDAR is on.' : 'Tap two points on a surface.' },
];

export default function ArScreen() {
  if (!isArAvailable) return <ArUnavailable />;
  return <ArExperience />;
}

function ArExperience() {
  const insets = useSafeAreaInsets();
  const arRef = useRef<SonicArViewRef>(null);
  const [assets] = useAssets([require('@/assets/ar/marker.png')]);
  const [mode, setMode] = useState<ArMode>('place');
  const [status, setStatus] = useState<string | null>(null);

  const current = MODES.find((m) => m.key === mode)!;

  function switchMode(next: ArMode) {
    setMode(next);
    setStatus(null);
  }

  return (
    <View style={styles.fill}>
      <SonicArView
        ref={arRef}
        style={StyleSheet.absoluteFill}
        mode={mode}
        markerUri={assets?.[0]?.localUri ?? undefined}
        markerWidth={MARKER_WIDTH_M}
        onPlaneDetected={() => mode === 'place' && setStatus('Surface found. Tap to place.')}
        onImageDetected={() => setStatus('Marker found!')}
        onMeasure={(e) => setStatus(`${(e.nativeEvent.meters * 100).toFixed(1)} cm`)}
        onError={(e) => setStatus(e.nativeEvent.message)}
      />

      <View style={[styles.top, { paddingTop: insets.top + Spacing.sm }]} pointerEvents="box-none">
        <View style={styles.segment}>
          {MODES.map((m) => (
            <Pressable
              key={m.key}
              onPress={() => switchMode(m.key)}
              style={[styles.segmentItem, m.key === mode && styles.segmentActive]}
              accessibilityRole="button"
              accessibilityState={{ selected: m.key === mode }}>
              <Text style={[styles.segmentText, m.key === mode && styles.segmentTextActive]}>{m.label}</Text>
            </Pressable>
          ))}
        </View>
      </View>

      <View style={[styles.bottom, { paddingBottom: Spacing.md }]} pointerEvents="box-none">
        <View style={styles.panel}>
          <Text style={styles.status}>{status ?? current.hint}</Text>
          <Pressable
            onPress={() => {
              setStatus(null);
              arRef.current?.reset();
            }}
            style={styles.reset}
            accessibilityRole="button">
            <Text style={styles.resetText}>Reset</Text>
          </Pressable>
        </View>
      </View>
    </View>
  );
}

function ArUnavailable() {
  const backgroundColor = useThemeColor({}, 'background');
  return (
    <ScrollView
      style={{ backgroundColor }}
      contentContainerStyle={styles.fallback}
      contentInsetAdjustmentBehavior="automatic">
      <Card
        title="AR needs the Team Sonic dev build"
        body="Expo Go can't run ARKit. Install the dev build on an iPhone (see mobile/README.md → AR). Every other tab works here."
      />
    </ScrollView>
  );
}

const glass = 'rgba(15, 23, 42, 0.72)';

const styles = StyleSheet.create({
  fill: { flex: 1, backgroundColor: '#000' },
  top: { position: 'absolute', top: 0, left: 0, right: 0, alignItems: 'center' },
  segment: { flexDirection: 'row', backgroundColor: glass, borderRadius: 999, padding: 4 },
  segmentItem: { paddingVertical: Spacing.sm, paddingHorizontal: Spacing.md, borderRadius: 999 },
  segmentActive: { backgroundColor: '#FFFFFF' },
  segmentText: { color: '#FFFFFF', fontWeight: '600', fontSize: 15 },
  segmentTextActive: { color: '#0F172A' },
  bottom: { position: 'absolute', bottom: 0, left: 0, right: 0, paddingHorizontal: Spacing.md },
  panel: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
    backgroundColor: glass,
    borderRadius: Radius.lg,
    padding: Spacing.md,
  },
  status: { flex: 1, color: '#FFFFFF', fontSize: 15, lineHeight: 20 },
  reset: { backgroundColor: '#FFFFFF', borderRadius: Radius.md, paddingVertical: Spacing.sm, paddingHorizontal: Spacing.md },
  resetText: { color: '#0F172A', fontWeight: '700' },
  fallback: { padding: Spacing.lg },
});
