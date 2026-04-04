class MongoCollectionInfo {
  final String databaseName;
  final String name;
  final int? documentCount;
  final double? storageSize;

  const MongoCollectionInfo({
    required this.databaseName,
    required this.name,
    this.documentCount,
    this.storageSize,
  });

  String get fullName => '$databaseName.$name';
}
