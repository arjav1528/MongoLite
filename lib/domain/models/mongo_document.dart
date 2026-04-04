class MongoDocument {
  final String databaseName;
  final String collectionName;
  final Map<String, dynamic> data;
  final DateTime fetchedAt;

  const MongoDocument({
    required this.databaseName,
    required this.collectionName,
    required this.data,
    required this.fetchedAt,
  });

  Object? get id => data['_id'];

  Map<String, dynamic> toJson() => data;
}
