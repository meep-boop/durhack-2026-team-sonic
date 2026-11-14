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

enum ModelName: String, Codable {
  case screw, bolt, arrow, screwdriver, hand
  case cablePlug = "cable-plug"
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

struct Expect: Codable, Equatable {
  enum Cable: String, Codable { case `in`, out }
  var port: String
  var cable: Cable
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
