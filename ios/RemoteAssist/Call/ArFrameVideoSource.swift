import CoreVideo
import Foundation
import VideoToolbox
import WebRTC
import os

/// Feeds ARKit's camera frames into WebRTC. ARKit owns the camera, so WebRTC's own capturer can't run.
///
/// Each frame is scaled into our own pooled NV12 buffer synchronously, on the AR session queue, with VideoToolbox's
/// hardware scaler, so ARKit gets its buffer back before `push` returns. Holding ARKit's buffers starves its pool and
/// stalls tracking. No Metal or Core Image is involved, which matters in the background, where iOS refuses GPU work.
final class ArFrameVideoSource {
  let source: RTCVideoSource
  private let capturer: RTCVideoCapturer

  private let width = 960
  private let height = 720

  /// Everything below is only touched on the AR session queue, except `enabled`, which has its own lock.
  private var transfer: VTPixelTransferSession?
  private var pool: CVPixelBufferPool?
  private var lastSent: TimeInterval = 0
  private let enabled = OSAllocatedUnfairLock(initialState: false)

  init(factory: RTCPeerConnectionFactory) {
    source = factory.videoSource()
    capturer = RTCVideoCapturer(delegate: source)
  }

  /// Turned on while a call wants the camera and the app is in the foreground. Safe from any thread.
  var isEnabled: Bool {
    get { enabled.withLock { $0 } }
    set { enabled.withLock { $0 = newValue } }
  }

  /// Called on the AR session queue for every camera frame. Throttles to the frame rate and returns quickly.
  func push(_ pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) {
    guard isEnabled else { return }
    // A hot phone sends fewer frames rather than letting tracking and the encoder fight for the chip.
    let hot = ProcessInfo.processInfo.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue
    let fps: Double = hot ? 12 : 20
    guard timestamp - lastSent >= 1 / fps, let output = makeBuffer(), let transfer = makeTransfer() else { return }
    guard VTPixelTransferSessionTransferImage(transfer, from: pixelBuffer, to: output) == noErr else { return }
    lastSent = timestamp

    // ARKit's image is landscape (home button right); the phone is held in portrait.
    let frame = RTCVideoFrame(
      buffer: RTCCVPixelBuffer(pixelBuffer: output),
      rotation: ._90,
      timeStampNs: Int64(timestamp * 1_000_000_000)
    )
    source.capturer(capturer, didCapture: frame)
  }

  private func makeTransfer() -> VTPixelTransferSession? {
    if transfer == nil {
      var session: VTPixelTransferSession?
      VTPixelTransferSessionCreate(allocator: nil, pixelTransferSessionOut: &session)
      if let session {
        // ARKit's 4:3 image fits 960×720 exactly; letterbox anything else instead of stretching it.
        VTSessionSetProperty(session, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_Letterbox)
        VTSessionSetProperty(session, key: kVTPixelTransferPropertyKey_RealTime, value: kCFBooleanTrue)
      }
      transfer = session
    }
    return transfer
  }

  private func makeBuffer() -> CVPixelBuffer? {
    if pool == nil {
      let attributes: [String: Any] = [
        // NV12 is what ARKit captures and what WebRTC's H.264/VP8 encoders take natively: no colour conversion.
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height,
        kCVPixelBufferIOSurfacePropertiesKey as String: [:],
      ]
      CVPixelBufferPoolCreate(nil, nil, attributes as CFDictionary, &pool)
    }
    guard let pool else { return nil }
    var buffer: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
    return buffer
  }
}
