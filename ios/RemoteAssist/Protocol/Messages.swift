import Foundation
import simd

// Hand mirror of the websocket messages in contracts/protocol.ts. fixtures/messages.json has one example of each;
// RemoteAssistTests decodes them all, so a contract change that isn't mirrored here fails the tests.

enum Role: String, Codable {
  case expert, user, rig
}

struct Pose: Codable, Equatable {
  var p: Vec3
  var q: Quat
}

struct Hello: Codable, Equatable {
  var protocolVersion: Int = 1
  var role: Role
  var client: String

  enum CodingKeys: String, CodingKey {
    case protocolVersion = "protocol"
    case role, client
  }
}

struct GuideSet: Codable, Equatable {
  var guide: Guide
}

struct StepSet: Codable, Equatable {
  var guideId: String
  var stepId: String
}

struct CalibSet: Codable, Equatable {
  var splatId: String
  var corners: [Vec3]
  var residual: Float
}

struct StepDone: Codable, Equatable {
  var guideId: String
  var rev: Int
  var stepId: String
  var doneId: String
  /// Phone clock, ms since the epoch, when the tap happened (it can arrive much later).
  var at: Int64
}

struct PoseUpdate: Codable, Equatable {
  var t: Int64
  var camera: Pose
  var markerTracked: Bool
}

struct StepVerified: Codable, Equatable {
  var guideId: String
  var stepId: String
  var ok: Bool
  var detail: String?
}

enum RtcSignal: Codable, Equatable {
  case offer(sdp: String)
  case answer(sdp: String)
  case candidate(candidate: String, sdpMid: String?, sdpMLineIndex: Int?)

  private enum Keys: String, CodingKey { case kind, sdp, candidate, sdpMid, sdpMLineIndex }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: Keys.self)
    switch try c.decode(String.self, forKey: .kind) {
    case "offer": self = .offer(sdp: try c.decode(String.self, forKey: .sdp))
    case "answer": self = .answer(sdp: try c.decode(String.self, forKey: .sdp))
    case "candidate":
      self = .candidate(
        candidate: try c.decode(String.self, forKey: .candidate),
        sdpMid: try c.decodeIfPresent(String.self, forKey: .sdpMid),
        sdpMLineIndex: try c.decodeIfPresent(Int.self, forKey: .sdpMLineIndex)
      )
    case let kind:
      throw DecodingError.dataCorruptedError(forKey: .kind, in: c, debugDescription: "unknown rtc signal kind \(kind)")
    }
  }

  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: Keys.self)
    switch self {
    case .offer(let sdp):
      try c.encode("offer", forKey: .kind)
      try c.encode(sdp, forKey: .sdp)
    case .answer(let sdp):
      try c.encode("answer", forKey: .kind)
      try c.encode(sdp, forKey: .sdp)
    case .candidate(let candidate, let sdpMid, let sdpMLineIndex):
      try c.encode("candidate", forKey: .kind)
      try c.encode(candidate, forKey: .candidate)
      // The contract types these as `string | null` and `number | null`: send null, don't drop the key.
      try c.encode(sdpMid, forKey: .sdpMid)
      try c.encode(sdpMLineIndex, forKey: .sdpMLineIndex)
    }
  }
}

struct RtcSignalMessage: Codable, Equatable {
  var signal: RtcSignal
}

struct Presence: Codable, Equatable {
  struct Client: Codable, Equatable {
    var role: Role
    var client: String
  }
  var clients: [Client]
}

struct ErrorMessage: Codable, Equatable {
  var message: String
  var about: String?
}

enum Message: Codable, Equatable {
  case hello(Hello)
  case guideSet(GuideSet)
  case stepSet(StepSet)
  case calibSet(CalibSet)
  case stepDone(StepDone)
  case pose(PoseUpdate)
  case stepVerified(StepVerified)
  case rtcSignal(RtcSignalMessage)
  case presence(Presence)
  case error(ErrorMessage)

  private enum TypeKey: String, CodingKey { case type }

  var type: String {
    switch self {
    case .hello: "hello"
    case .guideSet: "guide.set"
    case .stepSet: "step.set"
    case .calibSet: "calib.set"
    case .stepDone: "step.done"
    case .pose: "pose"
    case .stepVerified: "step.verified"
    case .rtcSignal: "rtc.signal"
    case .presence: "presence"
    case .error: "error"
    }
  }

  // The body's fields sit beside "type" in one flat object, so both are read from and written to the same container.
  init(from decoder: Decoder) throws {
    let type = try decoder.container(keyedBy: TypeKey.self).decode(String.self, forKey: .type)
    switch type {
    case "hello": self = .hello(try Hello(from: decoder))
    case "guide.set": self = .guideSet(try GuideSet(from: decoder))
    case "step.set": self = .stepSet(try StepSet(from: decoder))
    case "calib.set": self = .calibSet(try CalibSet(from: decoder))
    case "step.done": self = .stepDone(try StepDone(from: decoder))
    case "pose": self = .pose(try PoseUpdate(from: decoder))
    case "step.verified": self = .stepVerified(try StepVerified(from: decoder))
    case "rtc.signal": self = .rtcSignal(try RtcSignalMessage(from: decoder))
    case "presence": self = .presence(try Presence(from: decoder))
    case "error": self = .error(try ErrorMessage(from: decoder))
    default:
      throw DecodingError.dataCorrupted(.init(codingPath: [TypeKey.type], debugDescription: "unknown message type \(type)"))
    }
  }

  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: TypeKey.self)
    try c.encode(type, forKey: .type)
    switch self {
    case .hello(let m): try m.encode(to: encoder)
    case .guideSet(let m): try m.encode(to: encoder)
    case .stepSet(let m): try m.encode(to: encoder)
    case .calibSet(let m): try m.encode(to: encoder)
    case .stepDone(let m): try m.encode(to: encoder)
    case .pose(let m): try m.encode(to: encoder)
    case .stepVerified(let m): try m.encode(to: encoder)
    case .rtcSignal(let m): try m.encode(to: encoder)
    case .presence(let m): try m.encode(to: encoder)
    case .error(let m): try m.encode(to: encoder)
    }
  }
}

extension Vec3 {
  init(_ v: SIMD3<Float>) { self.init(v.x, v.y, v.z) }
}

extension Quat {
  init(_ q: simd_quatf) {
    self.init(x: q.imag.x, y: q.imag.y, z: q.imag.z, w: q.real)
  }

  init(x: Float, y: Float, z: Float, w: Float) {
    self.x = x
    self.y = y
    self.z = z
    self.w = w
  }
}
