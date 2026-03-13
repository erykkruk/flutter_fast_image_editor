/// Supported image formats.
enum ImageFormat {
  /// JPEG format.
  jpeg,

  /// PNG format.
  png,
}

/// Rectangular region of the image where an effect should be applied.
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

/// Radial (circular) region of the image where an effect should be applied.
///
/// Uses Alignment-style coordinates:
/// - [centerX]: -1.0 = left edge, 0.0 = center, 1.0 = right edge
/// - [centerY]: -1.0 = top edge, 0.0 = center, 1.0 = bottom edge
/// - [radius]: 0.0-1.0 as fraction of min(width, height)
///
/// ```dart
/// // Blur a circle in the center of the image
/// final radial = RadialRegion(centerX: 0.0, centerY: 0.0, radius: 0.3);
///
/// // Blur a circle in the top-left corner
/// final topLeft = RadialRegion(centerX: -1.0, centerY: -1.0, radius: 0.2);
/// ```
class RadialRegion {
  /// Horizontal center position using Alignment convention.
  /// -1.0 = left edge, 0.0 = center, 1.0 = right edge.
  final double centerX;

  /// Vertical center position using Alignment convention.
  /// -1.0 = top edge, 0.0 = center, 1.0 = bottom edge.
  final double centerY;

  /// Radius as fraction of min(image width, image height).
  /// Range: 0.0-1.0.
  final double radius;

  /// Creates a radial region with the given center and radius.
  const RadialRegion({
    this.centerX = 0.0,
    this.centerY = 0.0,
    required this.radius,
  });
}
