class PackMeta {
  final String countryCode;
  final int version;
  final int cameraCount;
  final int fileSizeBytes;
  final String checksumSha256;

  const PackMeta({
    required this.countryCode,
    required this.version,
    required this.cameraCount,
    required this.fileSizeBytes,
    required this.checksumSha256,
  });

  factory PackMeta.fromJson(Map<String, dynamic> json) {
    return PackMeta(
      countryCode: json['country_code'] as String,
      version: json['version'] as int,
      cameraCount: json['camera_count'] as int,
      fileSizeBytes: json['file_size_bytes'] as int,
      checksumSha256: json['checksum_sha256'] as String,
    );
  }
}
