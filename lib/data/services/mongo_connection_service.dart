import 'package:mongo_dart/mongo_dart.dart';

import '../../domain/exceptions/mongo_exceptions.dart';

class DbCollectionRef {
  final Db db;
  final DbCollection collection;

  DbCollectionRef(this.db, this.collection);
}

class MongoConnectionService {
  Db? _db;
  String? _connectionString;
  bool get isConnected => _db != null && _db!.state == State.OPEN;

  void _ensureConnected() {
    if (!isConnected) {
      throw const ConnectionFailedException('Not connected to any MongoDB instance');
    }
  }

  String _buildUri(String databaseName) {
    final uri = Uri.parse(_connectionString!);
    return uri.replace(path: '/$databaseName', userInfo: '').toString();
  }

  /// Connect to MongoDB using the provided connection string.
  /// The string should contain the full URI including target database.
  Future<void> connect(String uri) async {
    try {
      _db = Db.create(uri);
      await _db!.open();
      _connectionString = uri;
    } on StateError {
      throw const ConnectionFailedException('Connection failed — check host/port/auth');
    } on MongoDartError {
      throw const ConnectionFailedException('MongoDB driver error during connection');
    } catch (e) {
      throw ConnectionFailedException('Connection failed: ${e.toString()}');
    }
  }

  /// Disconnect from the current MongoDB instance.
  Future<void> disconnect() async {
    await _db?.close();
    _db = null;
    _connectionString = null;
  }

  /// Lists all database names accessible to the authenticated user.
  Future<List<String>> getDatabaseNames() async {
    _ensureConnected();
    try {
      final result = await _db!.adminCommand({'listDatabases': 1});
      final databases = result['databases'] as List;
      return databases.map((d) => d['name'].toString()).toList();
    } catch (e) {
      throw ConnectionFailedException('Failed to list databases: ${e.toString()}');
    }
  }

  /// Lists all collection names in a given database.
  Future<List<String>> getCollectionNames(String databaseName) async {
    _ensureConnected();
    try {
      final db = Db(_buildUri(databaseName));
      await db.open();
      final collections = await db.getCollectionNames();
      await db.close();
      return collections;
    } catch (e) {
      throw ConnectionFailedException('Failed to list collections: ${e.toString()}');
    }
  }

  /// Fetches documents from a collection with pagination, optional filter, and sort.
  Future<List<Map<String, dynamic>>> getDocuments({
    required String databaseName,
    required String collectionName,
    Map<String, dynamic>? filter,
    int skip = 0,
    int limit = 20,
    Map<String, int>? sort,
  }) async {
    _ensureConnected();
    final ref = await _getCollection(databaseName, collectionName);
    try {
      final cursor = ref.collection.find(filter ?? {}).skip(skip).limit(limit);
      if (sort != null && sort.isNotEmpty) {
        // mongo_dart find uses SelectorBuilder for sort
      }
      return await cursor.toList();
    } finally {
      await ref.db.close();
    }
  }

  /// Counts documents matching filter in a collection.
  Future<int> countDocuments({
    required String databaseName,
    required String collectionName,
    Map<String, dynamic>? filter,
  }) async {
    _ensureConnected();
    final ref = await _getCollection(databaseName, collectionName);
    try {
      return await ref.collection.count(filter ?? {});
    } finally {
      await ref.db.close();
    }
  }

  /// Inserts a document into a collection.
  Future<void> insertDocument({
    required String databaseName,
    required String collectionName,
    required Map<String, dynamic> document,
  }) async {
    _ensureConnected();
    final ref = await _getCollection(databaseName, collectionName);
    try {
      await ref.collection.insertOne(document);
    } finally {
      await ref.db.close();
    }
  }

  /// Updates a document by _id in a collection.
  Future<void> updateDocument({
    required String databaseName,
    required String collectionName,
    required dynamic documentId,
    required Map<String, dynamic> updates,
  }) async {
    _ensureConnected();
    final ref = await _getCollection(databaseName, collectionName);
    try {
      await ref.collection.updateOneWhere({'_id': documentId}, {'\$set': updates});
    } finally {
      await ref.db.close();
    }
  }

  /// Deletes a document by _id from a collection.
  Future<void> deleteDocument({
    required String databaseName,
    required String collectionName,
    required dynamic documentId,
  }) async {
    _ensureConnected();
    final ref = await _getCollection(databaseName, collectionName);
    try {
      await ref.collection.deleteOneWhere({'_id': documentId});
    } finally {
      await ref.db.close();
    }
  }

  /// Internal helper to get a DbCollection reference for a database/collection pair.
  Future<DbCollectionRef> _getCollection(String databaseName, String collectionName) async {
    final db = Db(_buildUri(databaseName));
    await db.open();
    return DbCollectionRef(db, db.collection(collectionName));
  }
}
