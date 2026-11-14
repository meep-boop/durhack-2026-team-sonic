import CoreImage
import CoreVideo
import WebRTC

/// Feeds ARKit's camera frames into WebRTC. ARKit owns the camera, so WebRTC's own capturer can't run; instead each
/// frame is scaled into our own buffer pool and handed over, which also returns ARKit's buffer at once (holding
/// ARKit's buffers starves its pool and stalls tracking).
final class ArFrameVideoSource {
  let source: RTCVideoSource
  private let capturer: RTCVideoCapturer
  private let context = CIContext(options: [.cacheIntermediates: false])
  private var pool: CVPixelBufferPool?
  private var lastSent: TimeInterval = 0
  private let queue = DispatchQueue(label: "ar-frame-video", qos: .userInitiated)
  private var busy = false

  private let width = 960
  private let height = 720
  private let fps: Double = 20

  init(factory: RTCPeerConnectionFactory) {
    source = factory.videoSource()
    capturer = RTCVideoCapturer(delegate: source)
  }

  /// Called from the AR session for every camera frame; drops frames to keep to `fps` and never queues a backlog.
  func push(_ pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) {
    guard timestamp - lastSent >= 1 / fps, !busy else { return }
    lastSent = timestamp
    busy = true
    let image = CIImage(cvPixelBuffer: pixelBuffer)
    queue.async { [weak self] in
      defer { self?.busy = false }
      guard let self, let output = self.makeBuffer() else { return }
      let scale = CGAffineTransform(scaleX: CGFloat(self.width) / image.extent.width, y: CGFloat(self.height) / image.extent.height)
      self.context.render(image.transformed(by: scale), to: output)
      // ARKit's image is landscape (home button right); the phone is held in portrait.
      let frame = RTCVideoFrame(
        buffer: RTCCVPixelBuffer(pixelBuffer: output),
        rotation: ._90,
        timeStampNs: Int64(timestamp * 1_000_000_000)
      )
      self.source.capturer(self.capturer, didCapture: frame)
    }
  }

  private func makeBuffer() -> CVPixelBuffer? {
    if pool == nil {
      let attributes: [String: Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
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
