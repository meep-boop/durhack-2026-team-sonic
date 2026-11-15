import { useEffect, useState } from "react";
import type { ScanInfo, SceneHandle } from "./scene.ts";
import { type Scan, SAMPLE_SPLAT, scansFromQuery } from "./scans.ts";
import { type ScanSource, scanKind, sourceName } from "./scanSource.ts";

export type ScanStatus =
  | { state: "loading"; name: string }
  | { state: "ready"; info: ScanInfo; sample: boolean }
  | { state: "failed"; name: string; error: string };

export type ScanSwitch = {
  scans: readonly Scan[];
  // The switch label of the scan on screen; empty for a file dropped on the view.
  active: string;
  status: ScanStatus;
  switchTo(scan: Scan): void;
  // A scan file dropped on the view; anything else is ignored.
  open(files: readonly File[]): void;
};

const scans = scansFromQuery(window.location.search);

export function useScan(scene: SceneHandle | null): ScanSwitch {
  const [status, setStatus] = useState<ScanStatus>({ state: "loading", name: sourceName(scans[0]!.source) });
  const [active, setActive] = useState(scans[0]!.label);

  const load = async (source: ScanSource) => {
    if (!scene) return;
    const name = sourceName(source);
    setStatus({ state: "loading", name });
    try {
      const info = await scene.loadScan(source);
      // Null means another load started meanwhile; that one sets the status.
      if (!info) return;
      setStatus({ state: "ready", info, sample: source.kind === "url" && source.url === SAMPLE_SPLAT });
    } catch (err) {
      setStatus({ state: "failed", name, error: err instanceof Error ? err.message : String(err) });
    }
  };

  useEffect(() => {
    if (scene) void load(scans[0]!.source);
  }, [scene]);

  return {
    scans,
    active,
    status,
    switchTo(scan) {
      setActive(scan.label);
      void load(scan.source);
    },
    open(files) {
      const file = files.find((f) => scanKind(f.name) !== null);
      if (!file) return;
      setActive("");
      void load({ kind: "file", file });
    },
  };
}
