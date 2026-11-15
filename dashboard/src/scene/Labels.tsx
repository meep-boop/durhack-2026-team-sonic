import { useEffect, useState } from "react";
import type { RelayClient } from "../relay/client.ts";
import { findLabels, placeLabels } from "./labels.ts";
import type { SceneHandle, SceneLabel } from "./scene.ts";

type Props = { scene: SceneHandle; relay: RelayClient; scanId: string };

// Claude takes tens of seconds on a detailed view; past this the relay has most likely restarted and lost the request.
const ANSWER_TIMEOUT_MS = 120_000;

type Ask = { state: "idle" } | { state: "asking" } | { state: "failed"; message: string };

// Labels are kept per scan, in this page only: a reload asks Claude again (not decided yet; see the board).
const labelsByScan = new Map<string, { model: string; labels: SceneLabel[] }>();

export function Labels({ scene, relay, scanId }: Props) {
  const [found, setFound] = useState(() => labelsByScan.get(scanId) ?? null);
  const [ask, setAsk] = useState<Ask>({ state: "idle" });
  const [query, setQuery] = useState("");
  const [highlight, setHighlight] = useState<string | null>(null);
  const [editing, setEditing] = useState<string | null>(null);

  useEffect(() => {
    setFound(labelsByScan.get(scanId) ?? null);
    setHighlight(null);
  }, [scanId]);

  useEffect(() => {
    scene.showLabels(found?.labels ?? [], highlight);
  }, [scene, found, highlight]);

  const keep = (next: { model: string; labels: SceneLabel[] }) => {
    labelsByScan.set(scanId, next);
    setFound(next);
  };

  const askClaude = () => {
    const snapshot = scene.snapshot();
    const requestId = crypto.randomUUID();
    const done = () => {
      offResult();
      offError();
      window.clearTimeout(timeout);
    };
    const timeout = window.setTimeout(() => {
      done();
      setAsk({ state: "failed", message: "no answer from the relay in 2 minutes" });
    }, ANSWER_TIMEOUT_MS);
    const offResult = relay.on("labels.result", (result) => {
      if (result.requestId !== requestId) return;
      done();
      // The scan may have changed while Claude was reading; its pixels only make sense on the scan they came from.
      if (scene.splatId() !== scanId) return setAsk({ state: "idle" });
      const labels = placeLabels(result.labels, (x, y) => scene.pointAt(snapshot, x, y), () => crypto.randomUUID());
      keep({ model: result.model, labels });
      setAsk({ state: "idle" });
    });
    const offError = relay.on("error", (error) => {
      if (error.about !== "labels.request") return;
      done();
      setAsk({ state: "failed", message: error.message });
    });
    const sent = relay.send({ type: "labels.request", requestId, image: snapshot.image, width: snapshot.width, height: snapshot.height });
    if (!sent) {
      done();
      return setAsk({ state: "failed", message: "the relay is offline" });
    }
    setAsk({ state: "asking" });
  };

  const search = (text: string) => {
    setQuery(text);
    const best = findLabels(found?.labels ?? [], text)[0];
    setHighlight(best?.id ?? null);
    if (best) scene.focusPoint(best.point);
  };

  const rename = (id: string, text: string) => {
    if (!found) return;
    const trimmed = text.trim();
    keep({ ...found, labels: found.labels.map((l) => (l.id === id && trimmed ? { ...l, text: trimmed } : l)) });
    setEditing(null);
  };

  const remove = (id: string) => {
    if (!found) return;
    keep({ ...found, labels: found.labels.filter((l) => l.id !== id) });
    if (highlight === id) setHighlight(null);
  };

  const matches = new Set(findLabels(found?.labels ?? [], query).map((l) => l.id));

  return (
    <div className="labels">
      <button type="button" onClick={askClaude} disabled={ask.state === "asking"}>
        {ask.state === "asking" ? "Asking Claude…" : found ? "Label this view again (AI, paid)" : "Label this view (AI, paid)"}
      </button>
      {ask.state === "failed" && <div className="error">Couldn't label: {ask.message}</div>}
      {found && (
        <>
          <div className="hint">
            <span className="tag ai">AI</span> {found.labels.length} labels by {found.model}: check them, fix or delete wrong ones
          </div>
          <input type="search" placeholder="Find a part, e.g. SSD" value={query} onChange={(e) => search(e.target.value)} />
          <ul>
            {found.labels.map((label) => (
              <li key={label.id} className={matches.has(label.id) ? "match" : undefined}>
                {editing === label.id ? (
                  <input
                    autoFocus
                    defaultValue={label.text}
                    onBlur={(e) => rename(label.id, e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") rename(label.id, e.currentTarget.value);
                      if (e.key === "Escape") setEditing(null);
                    }}
                  />
                ) : (
                  <button
                    type="button"
                    className="link"
                    onClick={() => {
                      setHighlight(label.id);
                      scene.focusPoint(label.point);
                    }}
                  >
                    {label.text}
                  </button>
                )}
                <button type="button" aria-label={`Rename ${label.text}`} onClick={() => setEditing(label.id)}>
                  ✎
                </button>
                <button type="button" aria-label={`Delete ${label.text}`} onClick={() => remove(label.id)}>
                  ✕
                </button>
              </li>
            ))}
          </ul>
        </>
      )}
    </div>
  );
}
