class MongoDatabaseInfo {
  final String name;
  final double? sizeOnDisk;
  final bool empty;

  const MongoDatabaseInfo({
    required this.name,
    this.sizeOnDisk,
    required this.empty,
  });
}
