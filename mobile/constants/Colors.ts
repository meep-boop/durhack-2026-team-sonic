// Team Sonic colours, light and dark. Screens read these through useThemeColor / Colors[scheme].
const brand = '#2563EB';
const brandDark = '#60A5FA';

export default {
  light: {
    text: '#0F172A',
    mutedText: '#64748B',
    background: '#F8FAFC',
    card: '#FFFFFF',
    border: '#E2E8F0',
    tint: brand,
    tabIconDefault: '#94A3B8',
    tabIconSelected: brand,
  },
  dark: {
    text: '#F1F5F9',
    mutedText: '#94A3B8',
    background: '#0B1120',
    card: '#151E32',
    border: '#1E293B',
    tint: brandDark,
    tabIconDefault: '#475569',
    tabIconSelected: brandDark,
  },
};

export const Spacing = { xs: 4, sm: 8, md: 16, lg: 24, xl: 32 };
export const Radius = { md: 12, lg: 16 };
