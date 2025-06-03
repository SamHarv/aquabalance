class TankVolumeCalculator {
  /// [TankVolumeCalculator] calculates the volume of a given tank based on dimensions

  /// [calculateRectVolume] takes in a height, width and length and returns the volume in litres
  int calculateRectVolume(double height, double width, double length) {
    final volume = height * width * length;
    return cubicMToLitres(volume);
  }

  /// [calculateCircVolume] takes in a diameter and height and returns the volume in litres
  /// This can also be used to calculate water volume if height is entered as water
  /// height rather than tank height
  int calculateCircVolume(double diameter, double height) {
    final radius = diameter / 2;
    final volume = 3.14 * radius * radius * height;
    return cubicMToLitres(volume);
  }

  /// [cubicMToLitres] converts cubic meters to litres
  int cubicMToLitres(double cubicMeters) {
    return (cubicMeters * 1000).round();
  }
}
