// What a scan is loaded from: a URL, or a file dropped on the page (Scaniverse exports land on the laptop as files,
// and we don't want to commit multi-MB scans just to look at them).
export type ScanSource = { kind: "url"; url: string } | { kind: "file"; file: File };

// Scaniverse makes either kind: a splat (fuzzy blobs, photo-real) or a textured mesh (exact surface to click on).
// The dashboard takes both and keeps whichever scan of the set comes out better (Max, 2026-11-15).
export type ScanKind = "splat" | "mesh";

const EXTENSIONS: Record<string, ScanKind> = {
  ply: "splat",
  spz: "splat",
  splat: "splat",
  ksplat: "splat",
  sog: "splat",
  usdz: "mesh",
  usd: "mesh",
  usdc: "mesh",
  glb: "mesh",
  gltf: "mesh",
};

export function scanKind(name: string): ScanKind | null {
  const dot = name.lastIndexOf(".");
  if (dot < 0) return null;
  return EXTENSIONS[name.slice(dot + 1).toLowerCase()] ?? null;
}

export function sourceName(source: ScanSource): string {
  if (source.kind === "file") return source.file.name;
  return source.url.split("/").pop() || source.url;
}
