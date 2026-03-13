/// Supported image formats.
enum ImageFormat {
  /// JPEG format.
  jpeg,

  /// PNG format.
  png,
}

/// Region of the image where an effect should be applied.
///
/// Values are percentages from each edge (0.0 to 1.0).
/// When all values are 0.0, the effect applies to the entire image.
///
/// ```dart
/// // Blur top 30% and bottom 30%, leaving middle untouched
/// final region = EditRegion(top: 0.3, bottom: 0.3);
///
/// // Apply effect to left half only
/// final leftHalf = EditRegion(left: 0.5);
/// ```
class EditRegion {
  /// Percentage from top edge (0.0-1.0).
  final double top;

  /// Percentage from bottom edge (0.0-1.0).
  final double bottom;

  /// Percentage from left edge (0.0-1.0).
  final double left;

  /// Percentage from right edge (0.0-1.0).
  final double right;

  /// Creates a region with the given edge percentages.
  const EditRegion({
    this.top = 0.0,
    this.bottom = 0.0,
    this.left = 0.0,
    this.right = 0.0,
  });

  /// Apply effect to the entire image.
  static const EditRegion full = EditRegion();
}
