class Country {
  final String code;
  final String name;
  final String? nameLocal;
  final String speedUnit;
  final int? packVersion;
  final int? cameraCount;

  const Country({
    required this.code,
    required this.name,
    this.nameLocal,
    this.speedUnit = 'kmh',
    this.packVersion,
    this.cameraCount,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      code: json['code'] as String,
      name: json['name'] as String,
      nameLocal: json['name_local'] as String?,
      speedUnit: json['speed_unit'] as String? ?? 'kmh',
      packVersion: json['pack_version'] as int?,
      cameraCount: json['camera_count'] as int?,
    );
  }
}
