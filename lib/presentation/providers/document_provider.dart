import 'package:flutter/foundation.dart';

import '../../domain/models/mongo_document.dart';
import '../../data/repositories/mongo_repository.dart';

class DocumentProvider extends ChangeNotifier {
  final MongoRepository _repository;

  List<MongoDocument> _documents = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 0;
  int _totalDocuments = 0;
  static const int _pageSize = 20;
  Map<String, dynamic>? _currentFilter;
  String? _selectedDatabase;
  String? _selectedCollection;

  DocumentProvider({required MongoRepository repository}) : _repository = repository;

  List<MongoDocument> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => (_totalDocuments / _pageSize).ceil();
  int get totalDocuments => _totalDocuments;
  bool get hasMore => _currentPage < totalPages;
  String? get selectedDatabase => _selectedDatabase;
  String? get selectedCollection => _selectedCollection;

  Future<void> loadDocuments({
    required String database,
    required String collection,
    bool reset = false,
  }) async {
    if (reset) {
      _documents.clear();
      _currentPage = 0;
    }

    _selectedDatabase = database;
    _selectedCollection = collection;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _totalDocuments = await _repository.countDocuments(
        database: database,
        collection: collection,
        filter: _currentFilter,
      );
      final docs = await _repository.getDocuments(
        database: database,
        collection: collection,
        filter: _currentFilter,
        skip: _currentPage * _pageSize,
        limit: _pageSize,
      );

      if (reset) {
        _documents = docs;
      } else {
        _documents.addAll(docs);
      }
      _currentPage++;
    } catch (e) {
      _error = 'Failed to load documents: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadNextPage() async {
    if (_isLoading || !hasMore) return;

    if (_selectedDatabase == null || _selectedCollection == null) return;

    await loadDocuments(
      database: _selectedDatabase!,
      collection: _selectedCollection!,
      reset: false,
    );
  }

  Future<void> refresh() async {
    if (_selectedDatabase == null || _selectedCollection == null) return;
    await loadDocuments(
      database: _selectedDatabase!,
      collection: _selectedCollection!,
      reset: true,
    );
  }

  void setFilter(Map<String, dynamic> filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  Future<void> applyFilterAndReload() async {
    if (_selectedDatabase == null || _selectedCollection == null) return;
    await loadDocuments(
      database: _selectedDatabase!,
      collection: _selectedCollection!,
      reset: true,
    );
  }

  Future<void> deleteDocument(MongoDocument document) async {
    try {
      await _repository.deleteDocument(
        database: document.databaseName,
        collection: document.collectionName,
        documentId: document.id,
      );
      _documents.removeWhere(
        (d) => d.id == document.id,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete document: ${e.toString()}';
      notifyListeners();
    }
  }

  void clearDocuments() {
    _documents.clear();
    _currentPage = 0;
    _totalDocuments = 0;
    _selectedDatabase = null;
    _selectedCollection = null;
    _currentFilter = null;
    _error = null;
    notifyListeners();
  }
}
