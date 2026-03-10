class InstalledPack {
  final String countryCode;
  final int version;
  final String filePath;
  final DateTime installedAt;

  const InstalledPack({
    required this.countryCode,
    required this.version,
    required this.filePath,
    required this.installedAt,
  });
}
