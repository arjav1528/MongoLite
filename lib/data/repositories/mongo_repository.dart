import '../services/mongo_connection_service.dart';
import '../../domain/models/mongo_database.dart';
import '../../domain/models/mongo_collection.dart';
import '../../domain/models/mongo_document.dart';

class MongoRepository {
  final MongoConnectionService _service;

  MongoRepository(this._service);

  Future<List<MongoDatabaseInfo>> getDatabases() async {
    final names = await _service.getDatabaseNames();
    return names.map((name) => MongoDatabaseInfo(name: name, empty: false)).toList();
  }

  Future<List<MongoCollectionInfo>> getCollections(String databaseName) async {
    final names = await _service.getCollectionNames(databaseName);
    return names.map((name) => MongoCollectionInfo(databaseName: databaseName, name: name)).toList();
  }

  Future<List<MongoDocument>> getDocuments({
    required String database,
    required String collection,
    Map<String, dynamic>? filter,
    int skip = 0,
    int limit = 20,
  }) async {
    final data = await _service.getDocuments(
      databaseName: database,
      collectionName: collection,
      filter: filter,
      skip: skip,
      limit: limit,
    );
    return data.map((d) => MongoDocument(
      databaseName: database,
      collectionName: collection,
      data: d,
      fetchedAt: DateTime.now(),
    )).toList();
  }

  Future<int> countDocuments({
    required String database,
    required String collection,
    Map<String, dynamic>? filter,
  }) async {
    return await _service.countDocuments(
      databaseName: database,
      collectionName: collection,
      filter: filter,
    );
  }

  Future<void> insertDocument(MongoDocument document) async {
    await _service.insertDocument(
      databaseName: document.databaseName,
      collectionName: document.collectionName,
      document: document.data,
    );
  }

  Future<void> updateDocument({
    required String database,
    required String collection,
    required dynamic documentId,
    required Map<String, dynamic> updates,
  }) async {
    await _service.updateDocument(
      databaseName: database,
      collectionName: collection,
      documentId: documentId,
      updates: updates,
    );
  }

  Future<void> deleteDocument({
    required String database,
    required String collection,
    required dynamic documentId,
  }) async {
    await _service.deleteDocument(
      databaseName: database,
      collectionName: collection,
      documentId: documentId,
    );
  }
}
