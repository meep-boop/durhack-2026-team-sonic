import type { StyleProp, ViewStyle } from 'react-native';

export type ArMode = 'place' | 'image' | 'measure';

export type SonicArViewProps = {
  mode: ArMode;
  /** file:// URI of the marker image (resolve it with expo-asset first). */
  markerUri?: string;
  /** Real-world width of the printed or on-screen marker, in metres. */
  markerWidth?: number;
  onPlaneDetected?: () => void;
  onImageDetected?: (event: { nativeEvent: { name: string } }) => void;
  onMeasure?: (event: { nativeEvent: { meters: number } }) => void;
  onError?: (event: { nativeEvent: { message: string } }) => void;
  style?: StyleProp<ViewStyle>;
};

export type SonicArViewRef = { reset(): Promise<void> };
