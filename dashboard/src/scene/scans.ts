// Which scans the dashboard offers. The demo has two of the same set, laptop closed and cover off, each with the
// marker in view, so the expert can switch between them. Scans are multi-MB and per-machine, so they sit in the
// git-ignored public/scans/ and are named in the URL rather than committed.
import type { SplatSource } from "./splatSource.ts";

export type Scan = { label: string; source: SplatSource };

// SAMPLE, not our scan: Spark's demo splat, so the viewport works before anyone has exported a Scaniverse file.
export const SAMPLE_SPLAT = "https://sparkjs.dev/assets/splats/butterfly.spz";

// A bare file name means public/scans/<name>; anything with a slash is used as given.
function resolve(value: string): SplatSource {
  return { kind: "url", url: value.includes("/") ? value : `/scans/${value}` };
}

// ?closed=<file>&open=<file> gives the Closed / Open switch; ?splat=<file or url> loads one scan; neither gives the
// sample. The file name is the scan's id for its calibration, so a rescan needs a new name, not an overwrite.
export function scansFromQuery(search: string): Scan[] {
  const params = new URLSearchParams(search);
  const scans: Scan[] = [];
  const closed = params.get("closed");
  const open = params.get("open");
  const splat = params.get("splat");
  if (closed) scans.push({ label: "Closed", source: resolve(closed) });
  if (open) scans.push({ label: "Open", source: resolve(open) });
  if (splat) scans.push({ label: "Scan", source: resolve(splat) });
  if (scans.length === 0) scans.push({ label: "SAMPLE", source: { kind: "url", url: SAMPLE_SPLAT } });
  return scans;
}
