import simd

// Hand mirror of contracts/protocol.ts (Ahmed's). Keep field names and shapes identical; a change there is a
// change here. Everything spatial is in the marker frame, in metres, so the phone never converts.

struct Vec3: Codable, Equatable {
  var x: Float
  var y: Float
  var z: Float

  var simd: SIMD3<Float> { SIMD3(x, y, z) }

  init(_ x: Float, _ y: Float, _ z: Float) {
    self.x = x
    self.y = y
    self.z = z
  }

  init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    x = try c.decode(Float.self)
    y = try c.decode(Float.self)
    z = try c.decode(Float.self)
  }

  func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(x)
    try c.encode(y)
    try c.encode(z)
  }
}

/// `[x, y, z, w]`, the order the contract and simd_quatf(ix:iy:iz:r:) both use.
struct Quat: Codable, Equatable {
  var x: Float
  var y: Float
  var z: Float
  var w: Float

  var simd: simd_quatf { simd_quatf(ix: x, iy: y, iz: z, r: w) }

  init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    x = try c.decode(Float.self)
    y = try c.decode(Float.self)
    z = try c.decode(Float.self)
    w = try c.decode(Float.self)
  }

  func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(x)
    try c.encode(y)
    try c.encode(z)
    try c.encode(w)
  }
}

/// Decodes any string: a model this build doesn't know yet (say one added to assets/models/ later) becomes
/// `.other` and is drawn as a stand-in, instead of failing the whole guide.set and leaving the phone on the old guide.
enum ModelName: Codable, Hashable {
  case screw, bolt, arrow, screwdriver, hand, cablePlug, ssd
  case other(String)

  static let known: [ModelName] = [.screw, .bolt, .arrow, .screwdriver, .hand, .cablePlug, .ssd]

  var rawValue: String {
    switch self {
    case .screw: "screw"
    case .bolt: "bolt"
    case .arrow: "arrow"
    case .screwdriver: "screwdriver"
    case .hand: "hand"
    case .cablePlug: "cable-plug"
    case .ssd: "ssd"
    case .other(let name): name
    }
  }

  init(rawValue: String) {
    self = Self.known.first { $0.rawValue == rawValue } ?? .other(rawValue)
  }

  init(from decoder: Decoder) throws {
    self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
  }

  func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    try c.encode(rawValue)
  }
}

enum Action: String, Codable {
  case unscrew, pull, push, flip, rotate90
}

struct Marker: Codable, Equatable {
  var name: String
  var width: Float
  var height: Float
}

struct GuideObject: Codable, Identifiable, Equatable {
  var id: String
  var model: ModelName
  var pos: Vec3
  var rot: Quat
  var size: Vec3
  var action: Action?
  var axis: Vec3
  var label: String?
  var cutoutId: String?
  /// What Ahmed's UNO Q rig should see after the step; the phone only shows the rig's verdict.
  var expect: Expect?
}

extension GuideObject {
  enum CodingKeys: String, CodingKey {
    case id, model, pos, rot, size, action, axis, label, cutoutId, expect
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(String.self, forKey: .id)
    model = try c.decode(ModelName.self, forKey: .model)
    pos = try c.decode(Vec3.self, forKey: .pos)
    rot = try c.decode(Quat.self, forKey: .rot)
    size = try c.decode(Vec3.self, forKey: .size)
    action = try c.decodeIfPresent(Action.self, forKey: .action)
    axis = try c.decode(Vec3.self, forKey: .axis)
    label = try c.decodeIfPresent(String.self, forKey: .label)
    cutoutId = try c.decodeIfPresent(String.self, forKey: .cutoutId)
    // The phone never uses `expect`, and its shape has already changed once (cable/port → region/present), which
    // made every guide fail to decode. Read it if it fits; never let it sink the guide.
    expect = try? c.decodeIfPresent(Expect.self, forKey: .expect)
  }
}

/// The stickered part (the SSD in the demo) present in, or gone from, a region of the Nicla Vision's view.
struct Expect: Codable, Equatable {
  var region: String
  var present: Bool
}

struct Step: Codable, Identifiable, Equatable {
  var id: String
  var text: String
  var objects: [GuideObject]
}

struct Guide: Codable, Equatable {
  var id: String
  var rev: Int
  var title: String
  var marker: Marker
  var steps: [Step]
}
