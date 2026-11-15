"""Builds the six built-in guide models as .glb (dashboard) and .usdz (phone) from one source of geometry.

Run: python assets/models/build_models.py   (needs usd-core, see requirements.txt)

Conventions every model follows, because the phone and dashboard place models by their origin:
- metres, +Y up, front faces wound counter-clockwise (glTF and USD agree on all three);
- the working tip (screw point, arrow point, fingertip, plug contacts) sits at the origin;
- the model extends up +Y from the tip, so +Y means "away from the part": pull moves +Y, push moves -Y.
"""
import json
import math
import struct
import sys
import tempfile
from pathlib import Path

ORANGE = (1.0, 0.45, 0.0)


class Mesh:
    def __init__(self):
        self.positions, self.normals, self.triangles = [], [], []

    def vertex(self, position, normal):
        self.positions.append(position)
        self.normals.append(normal)
        return len(self.positions) - 1

    def triangle(self, a, b, c):
        # Orient by the vertex normals so no part needs hand-checked winding.
        pa, pb, pc = self.positions[a], self.positions[b], self.positions[c]
        u = [pb[i] - pa[i] for i in range(3)]
        v = [pc[i] - pa[i] for i in range(3)]
        face = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
        normal = [sum(self.normals[k][i] for k in (a, b, c)) for i in range(3)]
        self.triangles.append((a, b, c) if sum(face[i] * normal[i] for i in range(3)) > 0 else (a, c, b))

    def quad(self, a, b, c, d):
        self.triangle(a, b, c)
        self.triangle(a, c, d)

    def cylinder(self, y0, y1, r0, r1, sides, cap0=True, cap1=True, centre=(0.0, 0.0), flat=False):
        """A frustum along Y from radius r0 at y0 to r1 at y1. Caps are skipped where a part joins another."""
        cx, cz = centre
        slope = (r0 - r1) / (y1 - y0)

        def ring_point(angle, y, r):
            return (cx + r * math.cos(angle), y, cz + r * math.sin(angle))

        def side_normal(angle):
            length = math.sqrt(1 + slope * slope)
            return (math.cos(angle) / length, slope / length, math.sin(angle) / length)

        angles = [2 * math.pi * i / sides for i in range(sides)]
        if flat:
            for i, a0 in enumerate(angles):
                a1 = angles[(i + 1) % sides]
                n = side_normal((a0 + a1) / 2 if i + 1 < sides else (a0 + 2 * math.pi + a1) / 2)
                self.quad(*(self.vertex(ring_point(a, y, r), n) for a, y, r in
                            ((a0, y0, r0), (a1, y0, r0), (a1, y1, r1), (a0, y1, r1))))
        else:
            bottom = [self.vertex(ring_point(a, y0, r0), side_normal(a)) for a in angles]
            top = [self.vertex(ring_point(a, y1, r1), side_normal(a)) for a in angles]
            for i in range(sides):
                j = (i + 1) % sides
                # A cone's point (r0 == 0) would make half of each quad a zero-area triangle. Every model's cones
                # point down at the tip, so only the bottom ring can be a point.
                if r0 == 0:
                    self.triangle(bottom[i], top[j], top[i])
                else:
                    self.quad(bottom[i], bottom[j], top[j], top[i])
        for y, r, ny, wanted in ((y0, r0, -1.0, cap0), (y1, r1, 1.0, cap1)):
            if wanted and r > 0:
                middle = self.vertex((cx, y, cz), (0.0, ny, 0.0))
                rim = [self.vertex(ring_point(a, y, r), (0.0, ny, 0.0)) for a in angles]
                for i in range(sides):
                    self.triangle(middle, rim[i], rim[(i + 1) % sides])

    def box(self, x0, x1, y0, y1, z0, z1):
        spans = [(x0, x1), (y0, y1), (z0, z1)]
        for axis in range(3):
            for side, normal_sign in ((0, -1.0), (1, 1.0)):
                normal = tuple(normal_sign if i == axis else 0.0 for i in range(3))
                fixed = spans[axis][side]
                u_axis, v_axis = [i for i in range(3) if i != axis]
                corners = []
                for u, v in ((0, 0), (1, 0), (1, 1), (0, 1)):
                    p = [0.0, 0.0, 0.0]
                    p[axis], p[u_axis], p[v_axis] = fixed, spans[u_axis][u], spans[v_axis][v]
                    corners.append(self.vertex(tuple(p), normal))
                self.quad(*corners)


def screw():
    m = Mesh()
    m.cylinder(0.000, 0.003, 0.0, 0.002, 10, cap1=False)
    m.cylinder(0.003, 0.013, 0.002, 0.002, 10, cap0=False, cap1=False)
    m.cylinder(0.013, 0.016, 0.004, 0.0035, 12)
    return m


def bolt():
    m = Mesh()
    m.cylinder(0.000, 0.024, 0.003, 0.003, 10, cap1=False)
    m.cylinder(0.024, 0.030, 0.0058, 0.0058, 6, flat=True)
    return m


def arrow():
    m = Mesh()
    m.cylinder(0.000, 0.016, 0.0, 0.008, 12)
    m.cylinder(0.016, 0.050, 0.003, 0.003, 10, cap0=False)
    return m


def screwdriver():
    m = Mesh()
    m.cylinder(0.000, 0.008, 0.0015, 0.0025, 8, cap1=False)
    m.cylinder(0.008, 0.100, 0.0025, 0.0025, 8, cap0=False, cap1=False)
    m.cylinder(0.100, 0.105, 0.0025, 0.012, 12, cap0=False, cap1=False)
    m.cylinder(0.105, 0.180, 0.014, 0.014, 12)
    return m


def hand():
    """A pointing hand: index fingertip at the origin, palm and wrist above it."""
    m = Mesh()
    m.cylinder(0.000, 0.006, 0.005, 0.008, 10, cap1=False)
    m.cylinder(0.006, 0.070, 0.008, 0.008, 10, cap0=False)
    m.box(-0.012, 0.050, 0.065, 0.150, -0.015, 0.015)
    m.box(0.005, 0.050, 0.065, 0.090, 0.015, 0.030)
    m.box(-0.026, -0.012, 0.085, 0.130, -0.008, 0.018)
    m.cylinder(0.150, 0.180, 0.024, 0.024, 12, centre=(0.019, 0.0))
    return m


def cable_plug():
    """An RJ45 plug: contacts at the origin, cable running up +Y."""
    m = Mesh()
    m.box(-0.00585, 0.00585, 0.000, 0.021, -0.004, 0.004)
    m.box(-0.002, 0.002, 0.006, 0.018, 0.004, 0.0055)
    m.cylinder(0.021, 0.032, 0.006, 0.004, 12)
    m.cylinder(0.032, 0.070, 0.003, 0.003, 10, cap0=False)
    return m


def ssd():
    """An M.2 2280 SSD (22 × 80 mm): contact edge at the origin, so pulling it out of its slot moves it along +Y."""
    m = Mesh()
    # The contact edge has the M-key notch, which is what makes it read as an SSD rather than a plain board.
    m.box(-0.0110, 0.0045, 0.000, 0.004, -0.0004, 0.0004)
    m.box(0.0065, 0.0110, 0.000, 0.004, -0.0004, 0.0004)
    m.box(-0.0110, 0.0110, 0.004, 0.080, -0.0004, 0.0004)
    for y0, y1 in ((0.008, 0.022), (0.028, 0.048), (0.054, 0.074)):
        m.box(-0.0085, 0.0085, y0, y1, 0.0004, 0.0016)
    return m


# Names must match ModelName in contracts/protocol.ts and are the file names both apps load.
MODELS = {
    "screw": screw,
    "bolt": bolt,
    "arrow": arrow,
    "screwdriver": screwdriver,
    "hand": hand,
    "cable-plug": cable_plug,
    "ssd": ssd,
}


def write_glb(mesh, name, path):
    positions = b"".join(struct.pack("<3f", *p) for p in mesh.positions)
    normals = b"".join(struct.pack("<3f", *n) for n in mesh.normals)
    # Every model is a few hundred vertices, so 16-bit indices (half the size of 32-bit) always fit.
    indices = b"".join(struct.pack("<H", i) for t in mesh.triangles for i in t)
    indices += b"\0" * (-len(indices) % 4)
    binary = positions + normals + indices
    count = len(mesh.positions)
    gltf = {
        "asset": {"version": "2.0", "generator": "assets/models/build_models.py"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"name": name, "mesh": 0}],
        "meshes": [{"name": name, "primitives": [
            {"attributes": {"POSITION": 0, "NORMAL": 1}, "indices": 2, "material": 0}]}],
        "materials": [{"name": "guide", "pbrMetallicRoughness": {
            "baseColorFactor": [*ORANGE, 1.0], "metallicFactor": 0.0, "roughnessFactor": 0.6}}],
        "buffers": [{"byteLength": len(binary)}],
        "bufferViews": [
            {"buffer": 0, "byteOffset": 0, "byteLength": len(positions), "target": 34962},
            {"buffer": 0, "byteOffset": len(positions), "byteLength": len(normals), "target": 34962},
            {"buffer": 0, "byteOffset": len(positions) + len(normals),
             "byteLength": 6 * len(mesh.triangles), "target": 34963},
        ],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": count, "type": "VEC3",
             "min": [min(p[i] for p in mesh.positions) for i in range(3)],
             "max": [max(p[i] for p in mesh.positions) for i in range(3)]},
            {"bufferView": 1, "componentType": 5126, "count": count, "type": "VEC3"},
            {"bufferView": 2, "componentType": 5123,
             "count": 3 * len(mesh.triangles), "type": "SCALAR"},
        ],
    }
    text = json.dumps(gltf, separators=(",", ":")).encode()
    text += b" " * (-len(text) % 4)
    path.write_bytes(
        struct.pack("<3I", 0x46546C67, 2, 12 + 8 + len(text) + 8 + len(binary))
        + struct.pack("<2I", len(text), 0x4E4F534A) + text
        + struct.pack("<2I", len(binary), 0x004E4942) + binary)


def write_usdz(mesh, name, path):
    from pxr import Gf, Sdf, Usd, UsdGeom, UsdShade, UsdUtils, Vt

    with tempfile.TemporaryDirectory() as scratch:
        layer_path = str(Path(scratch) / f"{path.stem}.usdc")
        stage = Usd.Stage.CreateNew(layer_path)
        UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
        UsdGeom.SetStageMetersPerUnit(stage, 1.0)
        # USD prim names can't contain "-", so cable-plug's prim is cable_plug; the file name keeps the contract name.
        root = UsdGeom.Xform.Define(stage, "/" + name.replace("-", "_"))
        stage.SetDefaultPrim(root.GetPrim())

        geometry = UsdGeom.Mesh.Define(stage, root.GetPath().AppendChild("geometry"))
        points = Vt.Vec3fArray([Gf.Vec3f(*p) for p in mesh.positions])
        geometry.CreatePointsAttr(points)
        geometry.CreateNormalsAttr(Vt.Vec3fArray([Gf.Vec3f(*n) for n in mesh.normals]))
        geometry.SetNormalsInterpolation(UsdGeom.Tokens.vertex)
        geometry.CreateFaceVertexCountsAttr([3] * len(mesh.triangles))
        geometry.CreateFaceVertexIndicesAttr([i for t in mesh.triangles for i in t])
        # Without this RealityKit treats the mesh as a subdivision surface and rounds off every edge.
        geometry.CreateSubdivisionSchemeAttr(UsdGeom.Tokens.none)
        geometry.CreateExtentAttr(UsdGeom.PointBased.ComputeExtent(points))

        material = UsdShade.Material.Define(stage, root.GetPath().AppendChild("guide"))
        shader = UsdShade.Shader.Define(stage, material.GetPath().AppendChild("surface"))
        shader.CreateIdAttr("UsdPreviewSurface")
        shader.CreateInput("diffuseColor", Sdf.ValueTypeNames.Color3f).Set(Gf.Vec3f(*ORANGE))
        shader.CreateInput("metallic", Sdf.ValueTypeNames.Float).Set(0.0)
        shader.CreateInput("roughness", Sdf.ValueTypeNames.Float).Set(0.6)
        material.CreateSurfaceOutput().ConnectToSource(shader.ConnectableAPI(), "surface")
        UsdShade.MaterialBindingAPI.Apply(geometry.GetPrim()).Bind(material)
        stage.Save()

        if not UsdUtils.CreateNewARKitUsdzPackage(Sdf.AssetPath(layer_path), str(path)):
            raise RuntimeError(f"couldn't package {path}")


USDZ_CHECKS = {"UsdCoreValidators", "UsdGeomValidators", "UsdShadeValidators", "UsdzValidators"}


def usdz_problems(path):
    # usd-core 26 replaced the old ARKit ComplianceChecker with these validators; the usdz ones cover the package
    # layout Apple's loader needs, the rest the stage metadata, geometry and material rules.
    from pxr import Usd, UsdValidation

    registry = UsdValidation.ValidationRegistry()
    names = [m.name for m in registry.GetAllValidatorMetadata() if USDZ_CHECKS & set(m.GetKeywords())]
    context = UsdValidation.ValidationContext(registry.GetOrLoadValidatorsByName(names))
    return [f"{e.GetName()}: {e.GetMessage()}" for e in context.Validate(Usd.Stage.Open(str(path)))]


def build(out_dir):
    for name, make in MODELS.items():
        mesh = make()
        write_glb(mesh, name, out_dir / f"{name}.glb")
        write_usdz(mesh, name, out_dir / f"{name}.usdz")
        problems = usdz_problems(out_dir / f"{name}.usdz")
        if problems:
            raise RuntimeError(f"{name}.usdz fails the USD checks: {problems}")
        print(f"{name}: {len(mesh.triangles)} triangles, "
              f"glb {(out_dir / f'{name}.glb').stat().st_size} B, usdz {(out_dir / f'{name}.usdz').stat().st_size} B")


if __name__ == "__main__":
    build(Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent)
