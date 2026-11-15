import XCTest
import simd
@testable import RemoteAssist

/// The geometry that decides whether a pin lands on the real screw.
final class PinMathTests: XCTestCase {
  /// A 1920×1440 sensor with the principal point in the centre and a 1500 px focal length, at the origin, unrotated.
  private let camera = CameraContext(
    transform: matrix_identity_float4x4,
    intrinsics: simd_float3x3(columns: (SIMD3(1500, 0, 0), SIMD3(0, 1500, 0), SIMD3(960, 720, 1))),
    imageResolution: CGSize(width: 1920, height: 1440),
    timestamp: 0
  )

  func testUprightCornersMapToTheRightSensorCorners() {
    let size = camera.imageResolution
    // The upright photo is the sensor image turned a quarter clockwise, so upright top-left is sensor bottom-left.
    XCTAssertEqual(PinMath.sensorPixel(for: CGPoint(x: 0, y: 0), resolution: size), CGPoint(x: 0, y: 1440))
    XCTAssertEqual(PinMath.sensorPixel(for: CGPoint(x: 1, y: 0), resolution: size), CGPoint(x: 0, y: 0))
    XCTAssertEqual(PinMath.sensorPixel(for: CGPoint(x: 0, y: 1), resolution: size), CGPoint(x: 1920, y: 1440))
    XCTAssertEqual(PinMath.sensorPixel(for: CGPoint(x: 0.5, y: 0.5), resolution: size), CGPoint(x: 960, y: 720))
  }

  func testSensorToUprightRoundTrips() {
    let point = CGPoint(x: 0.3, y: 0.8)
    let pixel = PinMath.sensorPixel(for: point, resolution: camera.imageResolution)
    let back = PinMath.uprightPoint(forSensorPixel: pixel, resolution: camera.imageResolution)
    XCTAssertEqual(back.x, point.x, accuracy: 1e-9)
    XCTAssertEqual(back.y, point.y, accuracy: 1e-9)
  }

  func testCentreOfThePhotoLooksStraightAhead() {
    let ray = PinMath.ray(for: CGPoint(x: 0.5, y: 0.5), in: camera)
    XCTAssertEqual(ray.origin, .zero)
    XCTAssertEqual(ray.direction.x, 0, accuracy: 1e-6)
    XCTAssertEqual(ray.direction.y, 0, accuracy: 1e-6)
    XCTAssertEqual(ray.direction.z, -1, accuracy: 1e-6)
  }

  func testTopOfThePhotoIsTheCameraPlusY() {
    // Upright right edge is sensor row 0, the top of the sensor image: camera +Y. Upright bottom edge is the sensor's
    // last column: camera +X.
    let right = PinMath.ray(for: CGPoint(x: 1, y: 0.5), in: camera)
    XCTAssertGreaterThan(right.direction.y, 0.3)
    XCTAssertEqual(right.direction.x, 0, accuracy: 1e-6)
    let bottom = PinMath.ray(for: CGPoint(x: 0.5, y: 1), in: camera)
    XCTAssertGreaterThan(bottom.direction.x, 0.3)
    XCTAssertEqual(bottom.direction.y, 0, accuracy: 1e-6)
  }

  func testRayFollowsTheCameraPose() {
    var moved = camera
    moved.transform.columns.3 = SIMD4(1, 2, 3, 1)
    let ray = PinMath.ray(for: CGPoint(x: 0.5, y: 0.5), in: moved)
    XCTAssertEqual(ray.origin, SIMD3(1, 2, 3))
    XCTAssertEqual(ray.direction.z, -1, accuracy: 1e-6)
  }

  func testRayMeetsADeskBelow() {
    // Camera 40 cm above a desk, looking straight down (rotate -90° about X so -Z points down).
    var looking = camera
    looking.transform = simd_float4x4(simd_quatf(angle: -.pi / 2, axis: [1, 0, 0]))
    looking.transform.columns.3 = SIMD4(0, 0.4, 0, 1)
    let ray = PinMath.ray(for: CGPoint(x: 0.5, y: 0.5), in: looking)
    let hit = PinMath.intersect(origin: ray.origin, direction: ray.direction, planePoint: .zero, planeNormal: [0, 1, 0])
    XCTAssertNotNil(hit)
    XCTAssertEqual(hit?.y ?? 1, 0, accuracy: 1e-5)
    XCTAssertEqual(hit?.x ?? 1, 0, accuracy: 1e-5)
    XCTAssertEqual(hit?.z ?? 1, 0, accuracy: 1e-5)
  }

  func testNoHitBehindTheCamera() {
    XCTAssertNil(PinMath.intersect(origin: [0, 1, 0], direction: [0, 1, 0], planePoint: .zero, planeNormal: [0, 1, 0]))
  }

  func testStandingPutsYAlongTheNormal() {
    let matrix = PinMath.standing(at: [1, 2, 3], normal: [0, 0, 1])
    let up = SIMD3(matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z)
    XCTAssertEqual(simd_distance(up, [0, 0, 1]), 0, accuracy: 1e-5)
    XCTAssertEqual(SIMD3(matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z), SIMD3(1, 2, 3))
  }


  func testEdgeGlowSitsWhereTheDirectionLeavesTheScreen() {
    let size = CGSize(width: 400, height: 800)
    XCTAssertEqual(SpotlightOverlay.edgePoint(CGVector(dx: 1, dy: 0), in: size), CGPoint(x: 400, y: 400))
    XCTAssertEqual(SpotlightOverlay.edgePoint(CGVector(dx: 0, dy: -1), in: size), CGPoint(x: 200, y: 0))
    let corner = SpotlightOverlay.edgePoint(CGVector(dx: -0.6, dy: 0.8), in: size)
    XCTAssertEqual(corner.x, 0, accuracy: 1e-9)
  }
}
