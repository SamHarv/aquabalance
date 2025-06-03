class Tank {
  /// [Tank] model
  final String id; // id for tank
  int capacity; // tank capacity in L
  int waterLevel; // current tank water level in L
  bool isRectangular; // tank is rectangular (true) or circular (false)
  double
  length; // tank length from front to back in m for rectangular calculation
  double
  width; // tank width from left to right in m for rectangular calculation
  double height; // tank height in m
  double waterHeight; // tank water height in m
  double diameter; // tank diameter in m for circular calculation

  Tank({
    required this.id,
    this.capacity = 0,
    this.waterLevel = 0,
    this.isRectangular = false, // default to circular (more common)
    this.length = 0,
    this.width = 0,
    this.height = 0,
    this.waterHeight = 0,
    this.diameter = 0,
  });

  // Convert Tank to JSON for SharedPreferences storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'capacity': capacity,
      'waterLevel': waterLevel,
      'isRectangular': isRectangular,
      'length': length,
      'width': width,
      'height': height,
      'waterHeight': waterHeight,
      'diameter': diameter,
    };
  }

  // Create Tank from JSON
  factory Tank.fromJson(Map<String, dynamic> json) {
    return Tank(
      id: json['id'] ?? '',
      capacity: json['capacity'] ?? 0,
      waterLevel: json['waterLevel'] ?? 0,
      isRectangular: json['isRectangular'] ?? true,
      length: (json['length'] ?? 0).toDouble(),
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      waterHeight: (json['waterHeight'] ?? 0).toDouble(),
      diameter: (json['diameter'] ?? 0).toDouble(),
    );
  }

  // Create a copy of the tank with updated values
  Tank copyWith({
    String? id,
    int? capacity,
    int? waterLevel,
    bool? isRectangular,
    double? length,
    double? width,
    double? height,
    double? waterHeight,
    double? diameter,
  }) {
    return Tank(
      id: id ?? this.id,
      capacity: capacity ?? this.capacity,
      waterLevel: waterLevel ?? this.waterLevel,
      isRectangular: isRectangular ?? this.isRectangular,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      waterHeight: waterHeight ?? this.waterHeight,
      diameter: diameter ?? this.diameter,
    );
  }
}
