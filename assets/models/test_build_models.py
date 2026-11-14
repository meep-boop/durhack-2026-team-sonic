"""Run: python -m unittest discover assets/models   (needs usd-core, see requirements.txt)"""
import json
import re
import struct
import tempfile
import unittest
from pathlib import Path

import build_models

REPO = Path(__file__).resolve().parents[2]


def read_glb(path):
    data = path.read_bytes()
    magic, version, length = struct.unpack_from("<3I", data, 0)
    json_length = struct.unpack_from("<I", data, 12)[0]
    gltf = json.loads(data[20:20 + json_length])
    binary = data[20 + json_length + 8:]

    def accessor(i, item_format):
        a = gltf["accessors"][i]
        view = gltf["bufferViews"][a["bufferView"]]
        return list(struct.iter_unpack(item_format, binary[view["byteOffset"]:view["byteOffset"] + view["byteLength"]]))

    positions = accessor(0, "<3f")
    normals = accessor(1, "<3f")
    indices = [i for (i,) in accessor(2, "<H")][:gltf["accessors"][2]["count"]]
    return {"magic": magic, "version": version, "length": length, "size": len(data), "gltf": gltf,
            "positions": positions, "normals": normals, "triangles": list(zip(*[iter(indices)] * 3))}


class BuiltModels(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scratch = tempfile.TemporaryDirectory()
        cls.out = Path(cls.scratch.name)
        build_models.build(cls.out)
        cls.glbs = {name: read_glb(cls.out / f"{name}.glb") for name in build_models.MODELS}

    @classmethod
    def tearDownClass(cls):
        cls.scratch.cleanup()

    def test_names_match_the_contract(self):
        contract = (REPO / "contracts" / "protocol.ts").read_text(encoding="utf-8")
        union = re.search(r"export type ModelName\s*=\s*([^;]+);", contract).group(1)
        self.assertEqual(set(re.findall(r'"([^"]+)"', union)), set(build_models.MODELS))

    def test_glb_is_well_formed(self):
        for name, glb in self.glbs.items():
            with self.subTest(name):
                self.assertEqual((glb["magic"], glb["version"]), (0x46546C67, 2))
                self.assertEqual(glb["length"], glb["size"])
                self.assertEqual(len(glb["positions"]), len(glb["normals"]))
                self.assertTrue(all(i < len(glb["positions"]) for t in glb["triangles"] for i in t))
                accessor = glb["gltf"]["accessors"][0]
                for axis in range(3):
                    self.assertAlmostEqual(accessor["min"][axis], min(p[axis] for p in glb["positions"]), places=6)
                    self.assertAlmostEqual(accessor["max"][axis], max(p[axis] for p in glb["positions"]), places=6)

    def test_tip_is_at_the_origin_and_the_model_rises_along_plus_y(self):
        for name, glb in self.glbs.items():
            with self.subTest(name):
                lo = [min(p[i] for p in glb["positions"]) for i in range(3)]
                hi = [max(p[i] for p in glb["positions"]) for i in range(3)]
                self.assertAlmostEqual(lo[1], 0.0, places=6)
                self.assertGreater(hi[1], 0.0)
                bottom = [p for p in glb["positions"] if p[1] < 1e-6]
                self.assertLessEqual(min(p[0] for p in bottom), 0.0)
                self.assertGreaterEqual(max(p[0] for p in bottom), 0.0)
                self.assertLessEqual(min(p[2] for p in bottom), 0.0)
                self.assertGreaterEqual(max(p[2] for p in bottom), 0.0)

    def test_sizes_are_real_world_metres(self):
        tallest = {"screw": 0.016, "bolt": 0.030, "arrow": 0.050, "screwdriver": 0.180, "hand": 0.180,
                   "cable-plug": 0.070}
        for name, height in tallest.items():
            with self.subTest(name):
                self.assertAlmostEqual(max(p[1] for p in self.glbs[name]["positions"]), height, places=6)

    def test_faces_point_outwards(self):
        # A flipped triangle renders as a hole on the phone (RealityKit culls back faces).
        for name, glb in self.glbs.items():
            with self.subTest(name):
                for a, b, c in glb["triangles"]:
                    pa, pb, pc = (glb["positions"][i] for i in (a, b, c))
                    u = [pb[i] - pa[i] for i in range(3)]
                    v = [pc[i] - pa[i] for i in range(3)]
                    face = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
                    normal = [sum(glb["normals"][k][i] for k in (a, b, c)) for i in range(3)]
                    self.assertGreater(sum(face[i] * normal[i] for i in range(3)), 0)

    def test_models_stay_small(self):
        for name in build_models.MODELS:
            with self.subTest(name):
                self.assertLess((self.out / f"{name}.glb").stat().st_size, 10_000)
                self.assertLess((self.out / f"{name}.usdz").stat().st_size, 10_000)

    def test_usdz_matches_the_glb_and_passes_the_usd_checks(self):
        from pxr import Usd, UsdGeom

        for name, glb in self.glbs.items():
            with self.subTest(name):
                path = self.out / f"{name}.usdz"
                self.assertEqual(build_models.usdz_problems(path), [])
                stage = Usd.Stage.Open(str(path))
                self.assertEqual(UsdGeom.GetStageUpAxis(stage), UsdGeom.Tokens.y)
                self.assertEqual(UsdGeom.GetStageMetersPerUnit(stage), 1.0)
                mesh = UsdGeom.Mesh(stage.GetDefaultPrim().GetChild("geometry"))
                points = [tuple(p) for p in mesh.GetPointsAttr().Get()]
                indices = list(mesh.GetFaceVertexIndicesAttr().Get())
                self.assertEqual(len(points), len(glb["positions"]))
                for usd_point, glb_point in zip(points, glb["positions"]):
                    for axis in range(3):
                        self.assertAlmostEqual(usd_point[axis], glb_point[axis], places=6)
                self.assertEqual(indices, [i for t in glb["triangles"] for i in t])


if __name__ == "__main__":
    unittest.main()
