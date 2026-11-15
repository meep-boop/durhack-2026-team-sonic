import AVFoundation
import CoreMedia
import UIKit
import os

/// The live camera without RealityKit: ARKit's own frames handed to the compositor the way video plays, so it never
/// needs a Metal drawable. When RealityKit can't get one (the frozen or black camera), this still moves. It covers the
/// AR view only while the AR view isn't drawing: the 3D guide drops out for that moment, the camera never does.
final class CameraFeedView: UIView {
  private let display = AVSampleBufferDisplayLayer()
  /// Kept from main at init: UIKit's layer properties are main-only, the renderer is safe from any thread.
  private let renderer: AVSampleBufferVideoRenderer
  private let format = OSAllocatedUnfairLock<CMVideoFormatDescription?>(initialState: nil)

  override init(frame: CGRect) {
    renderer = display.sampleBufferRenderer
    super.init(frame: frame)
    // Taps go straight through to the AR view underneath, which still raycasts while it can't draw.
    isUserInteractionEnabled = false
    display.videoGravity = .resizeAspectFill
    layer.addSublayer(display)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  /// ARKit's image is landscape (home button right). Turned upright and cropped to fill the screen, which is the same
  /// centre crop ARView makes, so the spotlight's projected points still land on the right spot.
  override func layoutSubviews() {
    super.layoutSubviews()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    display.setAffineTransform(.identity)
    display.bounds = CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width)
    display.position = CGPoint(x: bounds.midX, y: bounds.midY)
    display.setAffineTransform(CGAffineTransform(rotationAngle: .pi / 2))
    CATransaction.commit()
  }

  /// Any thread, every camera frame. ARKit's buffer goes in as is (no copy) and only the newest frame is kept, so at
  /// most one or two of ARKit's buffers are ever held.
  func enqueue(_ pixelBuffer: CVPixelBuffer) {
    if renderer.status == .failed || renderer.requiresFlushToResumeDecoding { renderer.flush() }
    guard renderer.isReadyForMoreMediaData, let sample = makeSample(pixelBuffer) else { return }
    renderer.enqueue(sample)
  }

  private func makeSample(_ pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
    let description: CMVideoFormatDescription? = format.withLock { cached in
      if let cached, CMVideoFormatDescriptionMatchesImageBuffer(cached, imageBuffer: pixelBuffer) { return cached }
      var made: CMVideoFormatDescription?
      CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: pixelBuffer, formatDescriptionOut: &made)
      cached = made
      return made
    }
    guard let description else { return nil }
    var timing = CMSampleTimingInfo(
      duration: .invalid,
      presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
      decodeTimeStamp: .invalid
    )
    var sample: CMSampleBuffer?
    CMSampleBufferCreateReadyWithImageBuffer(
      allocator: nil, imageBuffer: pixelBuffer, formatDescription: description, sampleTiming: &timing, sampleBufferOut: &sample
    )
    guard let sample else { return nil }
    // Shown the moment it arrives instead of being scheduled against a clock, so frames never queue up.
    if let attachments = CMSampleBufferGetSampleAttachmentsArray(sample, createIfNecessary: true) as? [NSMutableDictionary] {
      attachments.first?[kCMSampleAttachmentKey_DisplayImmediately] = true
    }
    return sample
  }
}
