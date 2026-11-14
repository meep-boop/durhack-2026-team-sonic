enum MarkerSpec {
  static let imageName = "marker"

  /// The marker's real width as you show it (printed, or on a screen), measured with a ruler. ARKit takes this as
  /// truth: a wrong number scales every position and makes tracking jittery. The sample guide assumes 0.16 m.
  static let widthMeters: Float = 0.16
}
