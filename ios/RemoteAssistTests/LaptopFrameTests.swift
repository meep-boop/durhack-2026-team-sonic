import XCTest
import simd
@testable import RemoteAssist

final class LaptopFrameTests: XCTestCase {
  private let footprint = SIMD2<Float>(0.3578, 0.2333)
  private let up = SIMD3<Float>(0, 1, 0)

  /// A laptop lying flat, top edge along world +X, cover running towards +Z; the user looks with screen right = +X.
  private func flatFrame() throws -> LaptopFrame {
    let a = SIMD3<Float>(0.1, 0.75, -0.3)
    let c = a + SIMD3(footprint.x, 0, footprint.y)
    return try LaptopFrame.make(a: a, c: c, normal: up, footprint: footprint, screenRight: [1, 0, 0]).get()
  }

  func testCornersComeBackWithinAMillimetre() throws {
    let frame = try flatFrame()
    let corners = frame.corners
    XCTAssertEqual(simd_distance(corners[0], frame.origin), 0, accuracy: 0.001)
    XCTAssertEqual(simd_distance(corners[1], frame.origin + SIMD3(footprint.x, 0, 0)), 0, accuracy: 0.001)
    XCTAssertEqual(simd_distance(corners[2], frame.origin + SIMD3(footprint.x, 0, footprint.y)), 0, accuracy: 0.001)
    XCTAssertEqual(simd_distance(corners[3], frame.origin + SIMD3(0, 0, footprint.y)), 0, accuracy: 0.001)
  }

  func testScreenRightPicksTheMirrorImage() throws {
    // The user stands on the other side: screen right is -X, so the top edge must run along -X.
    let a = SIMD3<Float>(0, 0, 0)
    let c = SIMD3<Float>(-footprint.x, 0, -footprint.y)
    let frame = try LaptopFrame.make(a: a, c: c, normal: up, footprint: footprint, screenRight: [-1, 0, 0]).get()
    XCTAssertGreaterThan(simd_dot(frame.xAxis, [-1, 0, 0]), 0.99)
    XCTAssertEqual(simd_distance(frame.corners[2], c), 0, accuracy: 0.001)
  }

  func testMillimetresRoundTrip() throws {
    let frame = try flatFrame()
    let point = CGPoint(x: 120.5, y: 64.25)
    let back = frame.mm(of: frame.world(mm: point))
    XCTAssertEqual(back.x, point.x, accuracy: 0.01)
    XCTAssertEqual(back.y, point.y, accuracy: 0.01)
  }

  func testPinsStandOnTheCover() throws {
    let frame = try flatFrame()
    let transform = frame.transform(mm: CGPoint(x: 10, y: 10))
    let pinUp = SIMD3(transform.columns.1.x, transform.columns.1.y, transform.columns.1.z)
    XCTAssertGreaterThan(simd_dot(pinUp, up), 0.999)
  }

  func testTapsThatMissTheCornersAreRejected() {
    let a = SIMD3<Float>(0, 0, 0)
    XCTAssertEqual(LaptopFrame.make(a: a, c: [0.1, 0, 0.05], normal: up, footprint: footprint, screenRight: [1, 0, 0]), .failure(.tooClose))
    XCTAssertEqual(LaptopFrame.make(a: a, c: [0.6, 0, 0.4], normal: up, footprint: footprint, screenRight: [1, 0, 0]), .failure(.tooFar))
    XCTAssertEqual(LaptopFrame.make(a: a, c: a, normal: up, footprint: footprint, screenRight: [1, 0, 0]), .failure(.sameSpot))
  }
}

final class LaptopLayoutTests: XCTestCase {
  func testBuiltInLayoutGuessesNoScrews() {
    let layout = LaptopLayout.dellLatitude5530()
    XCTAssertFalse(layout.isTaught("the eight base cover screws"), "screw positions are taught, never invented")
    XCTAssertNotNil(layout.part(for: "the U-shaped notches on the top edge")?.zone)
    XCTAssertEqual(layout.footprintMetres.x, 0.3578, accuracy: 1e-6)
  }

  func testTeachingAndUndo() {
    var layout = LaptopLayout.dellLatitude5530()
    layout.teach(CGPoint(x: 12, y: 8), for: "the eight base cover screws")
    layout.teach(CGPoint(x: 180, y: 8), for: "the eight base cover screws")
    XCTAssertTrue(layout.isTaught("the eight base cover screws"))
    XCTAssertNotNil(layout.part(for: "the eight base cover screws")?.zone, "teaching keeps the zone")
    layout.undoLast(for: "the eight base cover screws")
    XCTAssertEqual(layout.part(for: "the eight base cover screws")?.points, [CGPoint(x: 12, y: 8)])
  }

  func testLayoutRoundTripsThroughJSON() throws {
    var layout = LaptopLayout.dellLatitude5530()
    layout.teach(CGPoint(x: 1.5, y: 2.5), for: "the screw that holds the SSD")
    let url = try XCTUnwrap(layout.exportFile())
    let back = try JSONDecoder().decode(LaptopLayout.self, from: Data(contentsOf: url))
    XCTAssertEqual(back, layout)
  }

  /// Every built-in key is a real step's `lookFor`, so a zone can't silently never show.
  func testLayoutKeysMatchTheSteps() {
    let keys = Set(LaptopLayout.dellLatitude5530().parts.keys)
    let lookFors = Set(VerifiedProcedures.latitude5530.steps.map(\.lookFor))
    XCTAssertTrue(keys.isSubset(of: lookFors), "unknown keys: \(keys.subtracting(lookFors))")
  }
}
