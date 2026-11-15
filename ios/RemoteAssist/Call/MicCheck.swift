import AVFoundation
import Observation

/// Three seconds of microphone level, for the system check: a dead mic, a missing permission or an audio session
/// that won't record shows up here, not as "the expert can't hear me".
@Observable
final class MicCheck {
  enum Status: Equatable {
    case idle, denied, listening, done(peak: Float), failed(String)
  }

  private(set) var status: Status = .idle
  /// 0…1, updated while listening.
  private(set) var level: Float = 0

  @ObservationIgnored private var engine: AVAudioEngine?
  @ObservationIgnored private let audio = AudioSessionCoordinator.shared
  @ObservationIgnored private var peak: Float = 0

  var permission: AVAudioApplication.recordPermission { AVAudioApplication.shared.recordPermission }

  func run() {
    guard status != .listening else { return }
    AVAudioApplication.requestRecordPermission { granted in
      DispatchQueue.main.async {
        guard granted else { self.status = .denied; return }
        self.start()
      }
    }
  }

  private func start() {
    status = .listening
    peak = 0
    level = 0
    let engine = AVAudioEngine()
    self.engine = engine
    audio.beginListening { [weak self] in
      let input = engine.inputNode
      let format = input.outputFormat(forBus: 0)
      guard format.sampleRate > 0 else {
        DispatchQueue.main.async { self?.status = .failed("The microphone has no input (another app may be using it)") }
        return
      }
      input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
        guard let samples = buffer.floatChannelData?[0] else { return }
        var sum: Float = 0
        for i in 0..<Int(buffer.frameLength) { sum += samples[i] * samples[i] }
        // RMS to a rough 0…1 scale: speech at arm's length lands around 0.3–0.7.
        let value = min(1, sqrt(sum / Float(max(buffer.frameLength, 1))) * 8)
        DispatchQueue.main.async {
          self?.level = value
          self?.peak = max(self?.peak ?? 0, value)
        }
      }
      do {
        engine.prepare()
        try engine.start()
      } catch {
        ARSessionController.log.error("Mic check: engine wouldn't start: \(error.localizedDescription, privacy: .public)")
        DispatchQueue.main.async { self?.status = .failed(error.localizedDescription) }
        return
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self?.stop() }
    }
  }

  private func stop() {
    guard let engine else { return }
    self.engine = nil
    audio.endListening {
      engine.stop()
      engine.inputNode.removeTap(onBus: 0)
    }
    if status == .listening { status = .done(peak: peak) }
    level = 0
  }
}
