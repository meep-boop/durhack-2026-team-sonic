import { requireNativeView, requireOptionalNativeModule } from 'expo';
import type { ComponentType, Ref } from 'react';

import type { SonicArViewProps, SonicArViewRef } from './SonicAr.types';

type SonicArNative = { isSupported(): boolean; hasLidar(): boolean };

// Optional on purpose: Expo Go and Android don't contain this module, and the rest of the app must still open there.
const native = requireOptionalNativeModule<SonicArNative>('SonicAr');

/** True only in our dev build, on an ARKit-capable iPhone. */
export const isArAvailable = native?.isSupported() ?? false;
export const hasLidar = native?.hasLidar() ?? false;

type NativeProps = SonicArViewProps & { ref?: Ref<SonicArViewRef> };

const NativeView: ComponentType<NativeProps> | null = native ? requireNativeView('SonicAr') : null;

export default function SonicArView(props: NativeProps) {
  if (!NativeView) return null;
  return <NativeView {...props} />;
}
