import { SparkRenderer, SplatMesh } from "@sparkjsdev/spark";
import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import type { Marker, Vec3 } from "../../../contracts/protocol.ts";
import type { SceneApi } from "./api.ts";
import { type Calibration, solveCalibration } from "./calibration.ts";
import { createFrameMeter } from "./frameMeter.ts";
import { createObjectLayer } from "./objects.ts";
import { type SplatSource, sourceName } from "./splatSource.ts";

export type SplatInfo = { name: string; splatCount: number; loadMs: number };
export type Corners = [Vec3, Vec3, Vec3, Vec3];

// The scene's own controls on top of what the guide builder may call: loading scans and calibrating them.
export type SceneHandle = SceneApi & {
  // Resolves to null when a newer load, or dispose(), overtook this one: only the latest load reaches the scene.
  loadSplat(source: SplatSource): Promise<SplatInfo | null>;
  // The scan on screen, by file name: the id its calibration is kept under.
  splatId(): string | null;
  // The next click on the scan, in scan coordinates (calibration's own clicks). Esc resolves to null.
  pickScanPoint(): Promise<Vec3 | null>;
  // Marks the corners clicked so far, so the expert sees which ones are done.
  showCornerClicks(points: readonly Vec3[]): void;
  // Keeps a scan's calibration and applies it if that scan is on screen. Throws if the corners don't solve.
  setCalibration(splatId: string, corners: Corners): void;
  fps(): number;
  dispose(): void;
};

export function createScene(container: HTMLElement, marker: Pick<Marker, "width" | "height">): SceneHandle {
  // Spark draws the splats itself; three's antialiasing only costs fill rate here.
  const renderer = new THREE.WebGLRenderer({ antialias: false });
  renderer.setPixelRatio(window.devicePixelRatio);
  container.appendChild(renderer.domElement);

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x111318);
  const camera = new THREE.PerspectiveCamera(60, 1, 0.01, 200);
  camera.position.set(0, 0.5, 2);

  scene.add(new SparkRenderer({ renderer }));
  // Splats carry their own colour; this only lights the guide's glTF models, which are black without it.
  scene.add(new THREE.HemisphereLight(0xffffff, 0x666666, 3));

  const controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;

  // Everything the guide places lives in here, in marker metres; its matrix is the calibration (marker → scan).
  const markerGroup = new THREE.Group();
  markerGroup.matrixAutoUpdate = false;
  markerGroup.visible = false;
  scene.add(markerGroup);
  markerGroup.add(onTop(markerOutline(marker)), onTop(new THREE.AxesHelper(0.1)));
  const objects = createObjectLayer(markerGroup);

  // Spark's raycast can land on splats too faint to see (its issues #497, #498), so every pick leaves a dot where
  // it actually hit, and the expert can tell a bad pick from a good one.
  const dots = new THREE.Group();
  scene.add(dots);
  const dotGeometry = new THREE.SphereGeometry(1, 12, 8);
  const dotMaterial = new THREE.MeshBasicMaterial({ color: 0x22d3ee, depthTest: false, transparent: true });
  let dotRadius = 0.005;

  const meter = createFrameMeter();
  const raycaster = new THREE.Raycaster();
  const calibrations = new Map<string, Calibration>();
  const calibratedListeners = new Set<(calibrated: boolean) => void>();
  const movedListeners = new Set<Parameters<SceneApi["onObjectMoved"]>[0]>();
  const clickedListeners = new Set<(objectId: string) => void>();
  let splat: SplatMesh | null = null;
  let currentId: string | null = null;
  let latestLoad = 0;
  let pendingPick: ((point: Vec3 | null) => void) | null = null;

  const resize = () => {
    const { clientWidth: w, clientHeight: h } = container;
    renderer.setSize(w, h, false);
    camera.aspect = w / Math.max(h, 1);
    camera.updateProjectionMatrix();
  };
  const observer = new ResizeObserver(resize);
  observer.observe(container);
  resize();

  renderer.setAnimationLoop((time) => {
    meter.tick(time);
    controls.update();
    objects.tick(time);
    renderer.render(scene, camera);
  });

  const isCalibrated = () => currentId !== null && calibrations.has(currentId);

  const applyCalibration = () => {
    const calibration = currentId ? calibrations.get(currentId) : undefined;
    if (calibration) markerGroup.matrix.fromArray(calibration.matrix);
    markerGroup.matrixWorldNeedsUpdate = true;
    markerGroup.visible = calibration !== undefined;
    calibratedListeners.forEach((listener) => listener(calibration !== undefined));
  };

  const showDot = (point: THREE.Vector3) => {
    const dot = new THREE.Mesh(dotGeometry, dotMaterial);
    dot.position.copy(point);
    dot.scale.setScalar(dotRadius);
    dot.renderOrder = 1;
    dots.add(dot);
  };

  const aimRaycaster = (event: PointerEvent) => {
    const rect = renderer.domElement.getBoundingClientRect();
    const ndc = new THREE.Vector2(((event.clientX - rect.left) / rect.width) * 2 - 1, -((event.clientY - rect.top) / rect.height) * 2 + 1);
    raycaster.setFromCamera(ndc, camera);
  };

  // A click is a press and release that barely moved; anything longer was the expert orbiting.
  let pressedAt: { x: number; y: number } | null = null;
  const onPointerDown = (event: PointerEvent) => {
    pressedAt = { x: event.clientX, y: event.clientY };
  };
  const onPointerUp = (event: PointerEvent) => {
    if (!pressedAt || Math.hypot(event.clientX - pressedAt.x, event.clientY - pressedAt.y) > 4) return;
    pressedAt = null;
    aimRaycaster(event);

    if (pendingPick) {
      if (!splat) return;
      // Spark sorts its hits nearest first.
      const hit = raycaster.intersectObject(splat, false)[0];
      if (!hit) return;
      dots.clear();
      showDot(hit.point);
      const resolve = pendingPick;
      pendingPick = null;
      resolve(hit.point.toArray() as Vec3);
      return;
    }

    if (!markerGroup.visible) return;
    const id = raycaster.intersectObjects(objects.hitTargets(), false)[0]?.object.userData.objectId as string | undefined;
    if (id) clickedListeners.forEach((listener) => listener(id));
  };
  const onKeyDown = (event: KeyboardEvent) => {
    if (event.key === "Escape") cancelPick();
  };
  renderer.domElement.addEventListener("pointerdown", onPointerDown);
  renderer.domElement.addEventListener("pointerup", onPointerUp);
  window.addEventListener("keydown", onKeyDown);

  function cancelPick() {
    const resolve = pendingPick;
    pendingPick = null;
    resolve?.(null);
  }

  const pickScanPoint = () => {
    cancelPick();
    return new Promise<Vec3 | null>((resolve) => {
      pendingPick = resolve;
    });
  };

  function frameOn(mesh: SplatMesh) {
    // Centres only: a few stray floaters far from the scan would otherwise drag the orbit target into empty space.
    const box = mesh.getBoundingBox(true);
    const centre = box.getCenter(new THREE.Vector3());
    const radius = box.getSize(new THREE.Vector3()).length() / 2 || 1;
    controls.target.copy(centre);
    camera.position.copy(centre).add(new THREE.Vector3(0, radius * 0.4, radius * 1.2));
    camera.near = radius / 1000;
    camera.far = radius * 100;
    camera.updateProjectionMatrix();
    dotRadius = radius / 400;
  }

  return {
    async loadSplat(source) {
      const load = ++latestLoad;
      const started = performance.now();
      const mesh =
        source.kind === "url"
          ? new SplatMesh({ url: source.url })
          : new SplatMesh({ fileBytes: await source.file.arrayBuffer(), fileName: source.file.name });
      await mesh.initialized;
      if (load !== latestLoad) {
        mesh.dispose();
        return null;
      }

      cancelPick();
      dots.clear();
      if (splat) {
        scene.remove(splat);
        splat.dispose();
      }
      splat = mesh;
      scene.add(mesh);
      frameOn(mesh);

      const name = sourceName(source);
      currentId = name;
      applyCalibration();
      const splatCount = mesh.packedSplats?.numSplats ?? mesh.extSplats?.numSplats ?? 0;
      return { name, splatCount, loadMs: performance.now() - started };
    },

    splatId: () => currentId,
    pickScanPoint,

    showCornerClicks(points) {
      dots.clear();
      for (const point of points) showDot(new THREE.Vector3().fromArray(point));
    },

    setCalibration(splatId, corners) {
      const calibration = solveCalibration(corners, marker);
      calibrations.set(splatId, calibration);
      if (splatId === currentId) {
        dots.clear();
        applyCalibration();
      }
    },

    isCalibrated,
    onCalibrated(listener) {
      calibratedListeners.add(listener);
      return () => calibratedListeners.delete(listener);
    },

    async pickPoint() {
      // Decided by Max (2026-11-15): nothing is placed until the scan is calibrated, because a position measured
      // from no marker would land in the wrong place on the phone.
      if (!isCalibrated()) return null;
      const point = await pickScanPoint();
      if (!point) return null;
      markerGroup.updateMatrixWorld();
      return markerGroup.worldToLocal(new THREE.Vector3().fromArray(point)).toArray() as Vec3;
    },

    showStep: (list) => objects.showStep(list),
    select: (id) => objects.select(id),
    previewAction: (id) => objects.previewAction(id),
    stopPreview: () => objects.stopPreview(),

    focus(objectId) {
      const group = objects.find(objectId);
      if (!group || !markerGroup.visible) return;
      const box = new THREE.Box3().setFromObject(group);
      const centre = box.getCenter(new THREE.Vector3());
      const distance = Math.max(box.getSize(new THREE.Vector3()).length() * 3, dotRadius * 40);
      const direction = camera.position.clone().sub(controls.target).normalize();
      controls.target.copy(centre);
      camera.position.copy(centre).addScaledVector(direction, distance);
    },

    onObjectMoved(listener) {
      movedListeners.add(listener);
      return () => movedListeners.delete(listener);
    },
    onObjectClicked(listener) {
      clickedListeners.add(listener);
      return () => clickedListeners.delete(listener);
    },

    fps: () => meter.fps(),
    dispose() {
      latestLoad++;
      cancelPick();
      renderer.setAnimationLoop(null);
      observer.disconnect();
      renderer.domElement.removeEventListener("pointerdown", onPointerDown);
      renderer.domElement.removeEventListener("pointerup", onPointerUp);
      window.removeEventListener("keydown", onKeyDown);
      controls.dispose();
      objects.dispose();
      dotGeometry.dispose();
      dotMaterial.dispose();
      splat?.dispose();
      renderer.dispose();
      renderer.domElement.remove();
    },
  };
}

// Spark draws its splats in three's transparent pass, after everything opaque, so an opaque overlay is painted
// over. Transparent and later in the order, an overlay draws after the splats and shows through them.
function onTop<T extends THREE.Line>(line: T): T {
  const material = line.material as THREE.Material;
  material.transparent = true;
  material.depthTest = false;
  line.renderOrder = 1;
  return line;
}

// The printed marker's edge, flat on y = 0, so the expert can see the fit sit on the print.
function markerOutline({ width, height }: Pick<Marker, "width" | "height">) {
  const w = width / 2;
  const h = height / 2;
  const points = [[-w, 0, -h], [w, 0, -h], [w, 0, h], [-w, 0, h]].map(([x, y, z]) => new THREE.Vector3(x, y, z));
  return new THREE.LineLoop(new THREE.BufferGeometry().setFromPoints(points), new THREE.LineBasicMaterial({ color: 0x22d3ee }));
}
