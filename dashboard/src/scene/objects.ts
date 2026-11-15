// Draws a step's objects inside the marker group, so every number is marker metres, exactly as the guide holds it
// and the phone draws it: the highlight box centred on `pos`, the model's tip at `pos`.
import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import type { GuideObject, ModelName } from "../../../contracts/protocol.ts";
import { previewPose } from "./preview.ts";

// Laura's built-in models; Vite serves them from ../assets (server.fs.allow) and copies them into the build.
const MODEL_URLS = import.meta.glob("../../../assets/models/*.glb", { query: "?url", import: "default", eager: true }) as Record<string, string>;

function modelUrl(name: ModelName): string | undefined {
  return MODEL_URLS[`../../../assets/models/${name}.glb`];
}

const BOX_COLOUR = 0xfacc15;
const SELECTED_COLOUR = 0xffffff;

type Drawn = { object: GuideObject; group: THREE.Group; box: THREE.LineSegments; hit: THREE.Mesh; model: THREE.Group };

export type ObjectLayer = {
  showStep(objects: readonly GuideObject[]): void;
  select(objectId: string | null): void;
  previewAction(objectId: string): void;
  stopPreview(): void;
  // Called every frame by the render loop.
  tick(time: number): void;
  // One hidden solid per object, for click-to-select raycasts; each carries its id in userData.
  hitTargets(): THREE.Object3D[];
  find(objectId: string): THREE.Group | undefined;
  dispose(): void;
};

export function createObjectLayer(parent: THREE.Object3D): ObjectLayer {
  const loader = new GLTFLoader();
  const models = new Map<ModelName, Promise<THREE.Group>>();
  const drawn = new Map<string, Drawn>();
  let selected: string | null = null;
  let preview: { id: string; started: number } | null = null;

  const loadModel = (name: ModelName) => {
    let model = models.get(name);
    if (!model) {
      const url = modelUrl(name);
      model = url ? loader.loadAsync(url).then((gltf) => drawAfterSplats(gltf.scene)) : Promise.reject(new Error(`no model file for ${name}`));
      models.set(name, model);
    }
    return model;
  };

  const boxFor = (size: GuideObject["size"]) => {
    const geometry = new THREE.EdgesGeometry(new THREE.BoxGeometry(...size));
    // Drawn over the splat: a box inside the scanned part would otherwise vanish behind its own surface.
    const material = new THREE.LineBasicMaterial({ color: BOX_COLOUR, depthTest: false, transparent: true });
    const box = new THREE.LineSegments(geometry, material);
    box.renderOrder = 1;
    return box;
  };

  // Raycasts ignore `visible`, so a hidden solid box makes the whole volume clickable, not just its thin edges.
  const hitMaterial = new THREE.MeshBasicMaterial();

  const remove = (id: string) => {
    const entry = drawn.get(id);
    if (!entry) return;
    parent.remove(entry.group);
    entry.box.geometry.dispose();
    (entry.box.material as THREE.Material).dispose();
    entry.hit.geometry.dispose();
    drawn.delete(id);
    if (preview?.id === id) preview = null;
  };

  const restModel = (entry: Drawn) => {
    entry.model.position.set(0, 0, 0);
    entry.model.quaternion.identity();
  };

  const paint = () => {
    for (const [id, { box }] of drawn) (box.material as THREE.LineBasicMaterial).color.set(id === selected ? SELECTED_COLOUR : BOX_COLOUR);
  };

  return {
    showStep(objects) {
      const keep = new Set(objects.map((o) => o.id));
      for (const id of [...drawn.keys()]) if (!keep.has(id)) remove(id);

      for (const object of objects) {
        let entry = drawn.get(object.id);
        const reshaped = entry && (entry.object.model !== object.model || entry.object.size.some((v, i) => v !== object.size[i]));
        if (reshaped) {
          remove(object.id);
          entry = undefined;
        }
        if (!entry) {
          const group = new THREE.Group();
          const box = boxFor(object.size);
          const hit = new THREE.Mesh(new THREE.BoxGeometry(...object.size), hitMaterial);
          hit.visible = false;
          hit.userData.objectId = object.id;
          const model = new THREE.Group();
          group.add(box, hit, model);
          parent.add(group);
          entry = { object, group, box, hit, model };
          drawn.set(object.id, entry);
          const target = entry;
          loadModel(object.model)
            .then((source) => {
              // The step may have moved on while the file loaded.
              if (drawn.get(object.id) === target) target.model.add(source.clone());
            })
            .catch((err: unknown) => console.error(`couldn't load model ${object.model}:`, err));
        }
        entry.object = object;
        entry.group.position.fromArray(object.pos);
        entry.group.quaternion.fromArray(object.rot);
      }
      paint();
    },

    select(objectId) {
      selected = objectId;
      paint();
    },

    previewAction(objectId) {
      const previous = preview && drawn.get(preview.id);
      if (previous) restModel(previous);
      preview = drawn.get(objectId)?.object.action ? { id: objectId, started: performance.now() } : null;
    },

    stopPreview() {
      const entry = preview && drawn.get(preview.id);
      if (entry) restModel(entry);
      preview = null;
    },

    tick(time) {
      const entry = preview && drawn.get(preview.id);
      const action = entry?.object.action;
      if (!preview || !entry || !action) return;
      // `axis` is in the marker frame; the model lives inside the object's own turn, so undo that turn first.
      const axis = new THREE.Vector3()
        .fromArray(entry.object.axis)
        .applyQuaternion(entry.group.quaternion.clone().invert())
        .normalize();
      const { slide, turn } = previewPose(action, time - preview.started);
      entry.model.position.copy(axis).multiplyScalar(slide);
      entry.model.quaternion.setFromAxisAngle(axis, turn);
    },

    hitTargets: () => [...drawn.values()].map((d) => d.hit),
    find: (objectId) => drawn.get(objectId)?.group,

    dispose() {
      for (const id of [...drawn.keys()]) remove(id);
      hitMaterial.dispose();
    },
  };
}

// Spark draws splats in three's transparent pass, which would paint over an opaque model sitting on the scanned
// part. Moving the model into that pass, after the splats, keeps it visible; it still hides its own back faces.
function drawAfterSplats(model: THREE.Group): THREE.Group {
  model.traverse((node) => {
    if (!(node instanceof THREE.Mesh)) return;
    node.renderOrder = 1;
    for (const material of [node.material].flat()) material.transparent = true;
  });
  return model;
}
