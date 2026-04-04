import 'package:mongo_dart/mongo_dart.dart';

import '../../domain/exceptions/mongo_exceptions.dart';

class MongoConnectionService {
  Db? _db;
  String? _connectionString;
  bool get isConnected => _db?.isConnected ?? false;

  void _ensureConnected() {
    if (!isConnected) {
      throw const ConnectionFailedException('Not connected to any MongoDB instance');
    }
  }

  String _buildUri(String databaseName) {
    final uri = Uri.parse(_connectionString!);
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$portPart/$databaseName';
  }

  /// Connect to MongoDB using the provided connection string.
  /// The string should contain the full URI including target database.
  Future<void> connect(String uri) async {
    try {
      _db = await Db.create(uri);
      await _db!.open();
      _connectionString = uri;
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
      final result = await _db!.listDatabases();
      return result.map((d) => d['name'].toString()).toList();
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
      return collections.whereType<String>().toList();
    } catch (e) {
      throw ConnectionFailedException('Failed to list collections: ${e.toString()}');
    }
  }

  /// Fetches documents from a collection with pagination and optional filter.
  Future<List<Map<String, dynamic>>> getDocuments({
    required String databaseName,
    required String collectionName,
    Map<String, dynamic>? filter,
    int skip = 0,
    int limit = 20,
  }) async {
    _ensureConnected();
    final dbRef = await _getDb(databaseName);
    try {
      final col = dbRef.collection(collectionName);
      final stream = col.find(filter);
      var count = 0;
      final results = <Map<String, dynamic>>[];
      await stream.forEach((doc) {
        if (count >= skip && results.length < limit) {
          results.add(doc);
        }
        count++;
      });
      return results;
    } finally {
      await dbRef.close();
    }
  }

  /// Counts documents matching filter in a collection.
  Future<int> countDocuments({
    required String databaseName,
    required String collectionName,
    Map<String, dynamic>? filter,
  }) async {
    _ensureConnected();
    final dbRef = await _getDb(databaseName);
    try {
      final col = dbRef.collection(collectionName);
      return await col.count(filter);
    } finally {
      await dbRef.close();
    }
  }

  /// Inserts a document into a collection.
  Future<void> insertDocument({
    required String databaseName,
    required String collectionName,
    required Map<String, dynamic> document,
  }) async {
    _ensureConnected();
    final dbRef = await _getDb(databaseName);
    try {
      final col = dbRef.collection(collectionName);
      await col.insertOne(document);
    } finally {
      await dbRef.close();
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
    final dbRef = await _getDb(databaseName);
    try {
      final col = dbRef.collection(collectionName);
      final modifier = ModifierBuilder();
      updates.forEach((key, value) {
        modifier.set(key, value);
      });
      await col.updateOne(where.eq('_id', documentId), modifier);
    } finally {
      await dbRef.close();
    }
  }

  /// Deletes a document by _id from a collection.
  Future<void> deleteDocument({
    required String databaseName,
    required String collectionName,
    required dynamic documentId,
  }) async {
    _ensureConnected();
    final dbRef = await _getDb(databaseName);
    try {
      final col = dbRef.collection(collectionName);
      await col.deleteOne(where.eq('_id', documentId));
    } finally {
      await dbRef.close();
    }
  }

  /// Internal helper to get a Db reference for a database.
  Future<Db> _getDb(String databaseName) async {
    final db = Db(_buildUri(databaseName));
    await db.open();
    return db;
  }
}
