// What a splat is loaded from: a URL, or a file dropped on the page (Scaniverse exports land on the laptop as
// files, and we don't want to commit multi-MB scans just to look at them).
export type SplatSource = { kind: "url"; url: string } | { kind: "file"; file: File };

const SPLAT_EXTENSIONS = ["ply", "spz", "splat", "ksplat", "sog"] as const;

export function isSplatFileName(name: string): boolean {
  const dot = name.lastIndexOf(".");
  if (dot < 0) return false;
  const ext = name.slice(dot + 1).toLowerCase();
  return SPLAT_EXTENSIONS.some((known) => known === ext);
}

export function sourceName(source: SplatSource): string {
  if (source.kind === "file") return source.file.name;
  return source.url.split("/").pop() || source.url;
}
