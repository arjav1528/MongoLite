import 'package:flutter/foundation.dart';

import '../../data/repositories/mongo_repository.dart';
import '../../domain/models/mongo_database.dart';
import '../../domain/models/mongo_collection.dart';

class DatabaseProvider extends ChangeNotifier {
  final MongoRepository _repository;

  List<MongoDatabaseInfo> _databases = [];
  List<MongoCollectionInfo> _collections = [];
  bool _isLoading = false;
  String? _error;

  DatabaseProvider({required MongoRepository repository}) : _repository = repository;

  List<MongoDatabaseInfo> get databases => _databases;
  List<MongoCollectionInfo> get collections => _collections;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDatabases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _databases = await _repository.getDatabases();
    } catch (e) {
      _error = 'Failed to load databases: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCollections(String databaseName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _collections = await _repository.getCollections(databaseName);
    } catch (e) {
      _error = 'Failed to load collections: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearData() {
    _databases.clear();
    _collections.clear();
    _error = null;
    notifyListeners();
  }
}
