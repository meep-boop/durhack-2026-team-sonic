enum MarkerSpec {
  static let imageName = "marker"

  /// Laura's printed marker (assets/marker/README.md), measured on the print with a ruler. ARKit takes this as
  /// truth: a wrong number scales every position and makes tracking jittery. A reprint must be measured again.
  static let widthMeters: Float = 0.18
}
