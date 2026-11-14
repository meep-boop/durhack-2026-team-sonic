import { SparkRenderer, SplatMesh } from "@sparkjsdev/spark";
import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { createFrameMeter } from "./frameMeter.ts";
import { type SplatSource, sourceName } from "./splatSource.ts";

export type SplatInfo = { name: string; splatCount: number; loadMs: number };

export type SceneHandle = {
  // Resolves to null when a newer load, or dispose(), overtook this one: only the latest load reaches the scene.
  loadSplat(source: SplatSource): Promise<SplatInfo | null>;
  fps(): number;
  dispose(): void;
};

export function createScene(container: HTMLElement): SceneHandle {
  // Spark draws the splats itself; three's antialiasing only costs fill rate here.
  const renderer = new THREE.WebGLRenderer({ antialias: false });
  renderer.setPixelRatio(window.devicePixelRatio);
  container.appendChild(renderer.domElement);

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x111318);
  const camera = new THREE.PerspectiveCamera(60, 1, 0.01, 200);
  camera.position.set(0, 0.5, 2);

  scene.add(new SparkRenderer({ renderer }));

  const controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;

  const meter = createFrameMeter();
  let splat: SplatMesh | null = null;
  let latestLoad = 0;

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
    renderer.render(scene, camera);
  });

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

      if (splat) {
        scene.remove(splat);
        splat.dispose();
      }
      splat = mesh;
      scene.add(mesh);
      frameOn(mesh);

      const name = sourceName(source);
      const splatCount = mesh.packedSplats?.numSplats ?? mesh.extSplats?.numSplats ?? 0;
      return { name, splatCount, loadMs: performance.now() - started };
    },
    fps: () => meter.fps(),
    dispose() {
      latestLoad++;
      renderer.setAnimationLoop(null);
      observer.disconnect();
      controls.dispose();
      splat?.dispose();
      renderer.dispose();
      renderer.domElement.remove();
    },
  };
}
