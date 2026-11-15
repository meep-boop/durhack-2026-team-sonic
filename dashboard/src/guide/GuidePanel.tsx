import { useEffect, useRef, useState } from "react";
import type { Action, Guide, GuideObject, ModelName, Vec3 } from "../../../contracts/protocol.ts";
import type { RelayClient } from "../relay/client.ts";
import type { SceneApi } from "../scene/api.ts";
import {
  addObject,
  addStep,
  createGuide,
  guideSetMessage,
  type MarkerAxis,
  modelUp,
  moveStep,
  quarterTurn,
  removeObject,
  removeStep,
  renameGuide,
  sendBlockers,
  setStepText,
  stepSetMessage,
  updateObject,
} from "./guide.ts";
import "./GuidePanel.css";
import { applyMessage, currentStepId, emptyProgress, type Progress, stepStatus, type StepStatus } from "./progress.ts";

const MODELS: ModelName[] = ["screw", "screwdriver", "ssd", "arrow", "hand", "bolt", "cable-plug"];
const ACTIONS: Action[] = ["unscrew", "pull", "push", "flip", "rotate90"];
// The Nicla's region names (hardware/nicla/main.py). The SSD swap only watches the bay.
const RIG_REGION = "ssd-bay";
const STATUS_LABEL: Record<StepStatus, string> = { todo: "", done: "done", checked: "✓ checked", "check-failed": "✗ check" };

const toCm = (metres: number) => Math.round(metres * 1000) / 10;

type Props = { scene: SceneApi; relay: RelayClient };

export function GuidePanel({ scene, relay }: Props) {
  const [guide, setGuide] = useState<Guide>(() => createGuide("Replace the SSD"));
  const [progress, setProgress] = useState<Progress>(() => emptyProgress(guide));
  const [stepId, setStepId] = useState<string | null>(null);
  const [objectId, setObjectId] = useState<string | null>(null);
  const [sent, setSent] = useState<Guide | null>(null);
  const [calibrated, setCalibrated] = useState(scene.isCalibrated());
  const [placing, setPlacing] = useState(false);
  const [newModel, setNewModel] = useState<ModelName>("screw");
  const [relayError, setRelayError] = useState<string | null>(null);
  // The step "+ Add step" just made, so its text box takes the typing straight away.
  const [addedStepId, setAddedStepId] = useState<string | null>(null);

  // Listeners live for the page's life, so they read the latest guide and sent copy through refs.
  const guideRef = useRef(guide);
  guideRef.current = guide;
  const sentRef = useRef(sent);
  sentRef.current = sent;
  const editedRef = useRef(false);

  const edit = (next: Guide) => {
    editedRef.current = true;
    setGuide(next);
  };

  const step = guide.steps.find((s) => s.id === stepId) ?? null;

  useEffect(() => scene.onCalibrated(setCalibrated), [scene]);

  useEffect(() => scene.showStep(step?.objects ?? []), [scene, step]);
  useEffect(() => scene.select(objectId), [scene, objectId]);

  useEffect(
    () =>
      scene.onObjectClicked((clicked) => {
        const owner = guideRef.current.steps.find((s) => s.objects.some((o) => o.id === clicked));
        if (!owner) return;
        setStepId(owner.id);
        setObjectId(clicked);
      }),
    [scene],
  );

  useEffect(
    () =>
      scene.onObjectMoved((moved, pos, rot) => {
        const owner = guideRef.current.steps.find((s) => s.objects.some((o) => o.id === moved));
        if (owner) edit(updateObject(guideRef.current, owner.id, moved, { pos, rot, axis: modelUp(rot) }));
      }),
    [scene],
  );

  useEffect(() => {
    const offs = [
      // On connect the relay replays the guide it saved. Adopt it only on a fresh page: once the expert has edited,
      // their copy is the newer one.
      relay.on("guide.set", ({ guide: saved }) => {
        if (editedRef.current) return;
        setGuide(saved);
        setSent(saved);
        setProgress(emptyProgress(saved));
      }),
      relay.on("step.done", (message) => setProgress((p) => applyMessage(p, guideRef.current, message))),
      relay.on("step.verified", (message) => setProgress((p) => applyMessage(p, guideRef.current, message))),
      relay.on("error", ({ message, about }) => setRelayError(about ? `${about}: ${message}` : message)),
      // `send` refuses while the link is down, so the last guide sent goes out again when it comes back.
      relay.onStatus((status) => {
        if (status === "connected" && sentRef.current) relay.send(guideSetMessage(sentRef.current));
      }),
    ];
    return () => offs.forEach((off) => off());
  }, [relay]);

  const send = () => {
    setRelayError(null);
    if (!relay.send(guideSetMessage(guide))) {
      setRelayError("The relay isn't connected. Send again when it is.");
      return;
    }
    if (sent?.id !== guide.id) setProgress(emptyProgress(guide));
    setSent(guide);
  };

  const jump = (id: string) => {
    if (!relay.send(stepSetMessage(guide, id))) setRelayError("The relay isn't connected.");
  };

  const openFile = async (file: File) => {
    try {
      const opened = JSON.parse(await file.text()) as Guide;
      edit(opened);
      setProgress(emptyProgress(opened));
      setStepId(opened.steps[0]?.id ?? null);
      setObjectId(null);
      setRelayError(null);
    } catch (err) {
      setRelayError(`Couldn't read ${file.name}: ${err instanceof Error ? err.message : String(err)}`);
    }
  };

  const place = async () => {
    if (!step) return;
    setPlacing(true);
    const point = await scene.pickPoint();
    setPlacing(false);
    if (point) addAt(point);
  };

  const addAt = (pos: Vec3) => {
    if (!step) return;
    const next = addObject(guideRef.current, step.id, newModel, pos);
    edit(next);
    setObjectId(next.steps.find((s) => s.id === step.id)!.objects.at(-1)!.id);
  };

  const blockers = sendBlockers(guide);
  const unsent = sent === null || sent !== guide;
  const current = currentStepId(guide, progress);

  return (
    <div className="guide-panel">
      <label className="field">
        Guide title
        <input value={guide.title} onChange={(e) => edit(renameGuide(guide, e.target.value))} />
      </label>
      <label className="open">
        Open a guide file…
        <input type="file" accept=".json,application/json" onChange={(e) => e.target.files?.[0] && openFile(e.target.files[0])} />
      </label>

      <ol className="steps">
        {guide.steps.map((s, i) => {
          const status = stepStatus(progress, s.id);
          return (
            <li key={s.id} className={`step ${s.id === stepId ? "selected" : ""} ${s.id === current ? "current" : ""}`}>
              <div className="step-head" onClick={() => setStepId(s.id)}>
                <span className="step-number">{i + 1}</span>
                <textarea
                  value={s.text}
                  placeholder="What should they do?"
                  rows={2}
                  autoFocus={s.id === addedStepId}
                  onFocus={() => setStepId(s.id)}
                  onChange={(e) => edit(setStepText(guide, s.id, e.target.value))}
                />
              </div>
              <div className="step-tools">
                <span className={`status status-${status}`} title={progress.checks[s.id]?.detail}>
                  {STATUS_LABEL[status]}
                  {progress.checks[s.id]?.detail ? `: ${progress.checks[s.id]!.detail}` : ""}
                </span>
                <button onClick={() => edit(moveStep(guide, s.id, i - 1))} disabled={i === 0} aria-label="Move up">↑</button>
                <button onClick={() => edit(moveStep(guide, s.id, i + 1))} disabled={i === guide.steps.length - 1} aria-label="Move down">↓</button>
                <button onClick={() => jump(s.id)} disabled={unsent} title={unsent ? "Send the guide first" : "Show this step on the phone"}>Jump</button>
                <button onClick={() => edit(removeStep(guide, s.id))} aria-label="Delete step">✕</button>
              </div>
            </li>
          );
        })}
      </ol>
      <button className="add-step" onClick={() => {
        const next = addStep(guide);
        edit(next);
        setStepId(next.steps.at(-1)!.id);
        setAddedStepId(next.steps.at(-1)!.id);
        setObjectId(null);
      }}>+ Add step</button>

      {step && (
        <section className="objects">
          <h3>Step {guide.steps.indexOf(step) + 1}: objects</h3>
          {step.objects.map((o) => (
            <ObjectEditor
              key={o.id}
              object={o}
              selected={o.id === objectId}
              onSelect={() => setObjectId(o.id)}
              onChange={(changes) => edit(updateObject(guide, step.id, o.id, changes))}
              onRemove={() => {
                edit(removeObject(guide, step.id, o.id));
                if (objectId === o.id) setObjectId(null);
              }}
              onPreview={() => scene.previewAction(o.id)}
            />
          ))}
          <div className="add-object">
            <select value={newModel} onChange={(e) => setNewModel(e.target.value as ModelName)}>
              {MODELS.map((m) => <option key={m}>{m}</option>)}
            </select>
            <button onClick={place} disabled={!calibrated || placing}>{placing ? "Click the scan… (Esc)" : "Place on scan"}</button>
            <button onClick={() => addAt([0, 0, 0])} title="At the marker's centre; type the position after">Add at marker</button>
          </div>
          {!calibrated && <p className="hint">Calibrate the scan to place by clicking. Typed positions work now.</p>}
          <button onClick={() => scene.stopPreview()}>Stop preview</button>
        </section>
      )}

      <footer className="send">
        {blockers.length > 0 && <ul className="blockers">{blockers.map((b) => <li key={b}>{b}</li>)}</ul>}
        {relayError && <p className="error">{relayError}</p>}
        <button className="primary" onClick={send} disabled={blockers.length > 0}>
          {unsent ? "Send to phone" : "Sent ✓"}
        </button>
        <span className="hint">rev {guide.rev}{sent && unsent ? ` · phone has rev ${sent.rev}` : ""}</span>
      </footer>
    </div>
  );
}

type EditorProps = {
  object: GuideObject;
  selected: boolean;
  onSelect(): void;
  onChange(changes: Partial<Omit<GuideObject, "id">>): void;
  onRemove(): void;
  onPreview(): void;
};

function ObjectEditor({ object, selected, onSelect, onChange, onRemove, onPreview }: EditorProps) {
  const setVec = (key: "pos" | "size", index: number, cm: number) => {
    const next = [...object[key]] as Vec3;
    next[index] = cm / 100;
    onChange({ [key]: next });
  };
  const turn = (about: MarkerAxis) => {
    const rot = quarterTurn(object.rot, about);
    onChange({ rot, axis: modelUp(rot) });
  };
  const expect = object.expect ? (object.expect.present ? "in" : "out") : "none";

  return (
    <div className={`object ${selected ? "selected" : ""}`} onClick={onSelect}>
      <div className="row">
        <select value={object.model} onChange={(e) => onChange({ model: e.target.value as ModelName })}>
          {MODELS.map((m) => <option key={m}>{m}</option>)}
        </select>
        <select value={object.action ?? ""} onChange={(e) => onChange({ action: (e.target.value || null) as Action | null })}>
          <option value="">no animation</option>
          {ACTIONS.map((a) => <option key={a}>{a}</option>)}
        </select>
        <button onClick={onPreview} disabled={!object.action}>▶</button>
        <button onClick={onRemove} aria-label="Delete object">✕</button>
      </div>
      <VecRow label="Position (cm)" values={object.pos} onChange={(i, cm) => setVec("pos", i, cm)} />
      <VecRow label="Box (cm)" values={object.size} min={0.1} onChange={(i, cm) => setVec("size", i, cm)} />
      <div className="row">
        Turn 90°
        <button onClick={() => turn("x")}>X</button>
        <button onClick={() => turn("y")}>Y</button>
        <button onClick={() => turn("z")}>Z</button>
        <button onClick={() => onChange({ rot: [0, 0, 0, 1], axis: [0, 1, 0] })}>Reset</button>
      </div>
      <label className="row">
        Rig check
        <select
          value={expect}
          onChange={(e) =>
            onChange({
              expect: e.target.value === "none" ? undefined : { region: RIG_REGION, present: e.target.value === "in" },
            })
          }
        >
          <option value="none">none</option>
          <option value="out">SSD gone from the bay</option>
          <option value="in">SSD back in the bay</option>
        </select>
      </label>
    </div>
  );
}

function VecRow({ label, values, min, onChange }: { label: string; values: Vec3; min?: number; onChange(i: number, cm: number): void }) {
  return (
    <div className="row vec">
      {label}
      {(["x", "y", "z"] as const).map((axis, i) => (
        <input
          key={axis}
          type="number"
          step={0.1}
          min={min}
          aria-label={`${label} ${axis}`}
          value={toCm(values[i]!)}
          onChange={(e) => e.target.value !== "" && onChange(i, Number(e.target.value))}
        />
      ))}
    </div>
  );
}
