// Turns a scan file into something the scene can show and click on, whichever kind Scaniverse made.
import { SplatMesh } from "@sparkjsdev/spark";
import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { USDLoader } from "three/addons/loaders/USDLoader.js";
import { type ScanKind, type ScanSource, scanKind, sourceName } from "./scanSource.ts";

export type LoadedScan = {
  object: THREE.Object3D;
  kind: ScanKind;
  // Splats for a splat, triangles for a mesh: how much detail the scan carries.
  count: number;
  bounds: THREE.Box3;
  dispose(): void;
};

export async function loadScan(source: ScanSource): Promise<LoadedScan> {
  const name = sourceName(source);
  const kind = scanKind(name);
  // A URL with no known extension is most likely the splat sample or a splat host.
  return kind === "mesh" ? loadMesh(source, name) : loadSplat(source);
}

async function loadSplat(source: ScanSource): Promise<LoadedScan> {
  const mesh =
    source.kind === "url"
      ? new SplatMesh({ url: source.url })
      : new SplatMesh({ fileBytes: await source.file.arrayBuffer(), fileName: source.file.name });
  await mesh.initialized;
  return {
    object: mesh,
    kind: "splat",
    count: mesh.packedSplats?.numSplats ?? mesh.extSplats?.numSplats ?? 0,
    // Centres only: a few stray floaters far from the scan would otherwise drag the framing into empty space.
    bounds: mesh.getBoundingBox(true),
    dispose: () => mesh.dispose(),
  };
}

function unlit(material: THREE.MeshStandardMaterial): THREE.MeshBasicMaterial {
  return new THREE.MeshBasicMaterial({ map: material.map ?? null, color: material.map ? 0xffffff : material.color });
}

async function loadMesh(source: ScanSource, name: string): Promise<LoadedScan> {
  const isGltf = /\.(glb|gltf)$/i.test(name);
  let root: THREE.Object3D;
  if (source.kind === "url") {
    root = isGltf ? (await new GLTFLoader().loadAsync(source.url)).scene : await new USDLoader().loadAsync(source.url);
  } else {
    const bytes = await source.file.arrayBuffer();
    root = isGltf
      ? (await new GLTFLoader().parseAsync(bytes, "")).scene
      : await new Promise<THREE.Object3D>((resolve, reject) => new USDLoader().parse(bytes, "", resolve, reject));
  }

  let triangles = 0;
  root.traverse((node) => {
    if (!(node instanceof THREE.Mesh)) return;
    const geometry = node.geometry as THREE.BufferGeometry;
    triangles += (geometry.index?.count ?? geometry.attributes.position?.count ?? 0) / 3;
    // A scan's lighting is baked into its photo texture, so lighting it again would darken it unevenly.
    const lit = node.material as THREE.MeshStandardMaterial | THREE.MeshStandardMaterial[];
    node.material = Array.isArray(lit) ? lit.map(unlit) : unlit(lit);
    // The texture moves to the new material, so only the old material itself is freed.
    [lit].flat().forEach((m) => m.dispose());
  });

  return {
    object: root,
    kind: "mesh",
    count: Math.round(triangles),
    bounds: new THREE.Box3().setFromObject(root),
    dispose() {
      root.traverse((node) => {
        if (!(node instanceof THREE.Mesh)) return;
        node.geometry.dispose();
        for (const material of [node.material].flat() as THREE.MeshBasicMaterial[]) {
          material.map?.dispose();
          material.dispose();
        }
      });
    },
  };
}
