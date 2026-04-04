import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mongolite/data/repositories/mongo_repository.dart';
import 'package:mongolite/domain/models/mongo_document.dart';
import 'package:mongolite/presentation/providers/document_provider.dart';

class FakeMongoRepository extends Fake implements MongoRepository {
  int? lastCountAnswer;
  List<MongoDocument>? lastDocsAnswer;
  Map<String, dynamic>? lastFilter;
  bool shouldThrow = false;
  String? throwError;

  @override
  Future<int> countDocuments({
    required String database,
    required String collection,
    Map<String, dynamic>? filter,
  }) async {
    if (shouldThrow) throw Exception(throwError ?? 'Failed');
    return lastCountAnswer ?? 0;
  }

  @override
  Future<List<MongoDocument>> getDocuments({
    required String database,
    required String collection,
    Map<String, dynamic>? filter,
    int skip = 0,
    int limit = 20,
  }) async {
    if (shouldThrow) throw Exception(throwError ?? 'Failed');
    lastFilter = filter;
    return lastDocsAnswer ?? [];
  }

  @override
  Future<void> deleteDocument({
    required String database,
    required String collection,
    required dynamic documentId,
  }) async {
    if (shouldThrow) throw Exception(throwError ?? 'Failed');
  }
}

void main() {
  group('DocumentProvider', () {
    late FakeMongoRepository fakeRepository;
    late DocumentProvider provider;

    setUp(() {
      fakeRepository = FakeMongoRepository();
      provider = DocumentProvider(repository: fakeRepository);
    });

    final now = DateTime.now();
    MongoDocument makeDoc(String id) => MongoDocument(
      databaseName: 'mydb',
      collectionName: 'users',
      data: {'_id': id},
      fetchedAt: now,
    );

    test('initial state has no documents', () {
      expect(provider.documents, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('loadDocuments fetches with pagination data', () async {
      fakeRepository.lastCountAnswer = 50;
      fakeRepository.lastDocsAnswer = [makeDoc('123')];

      await provider.loadDocuments(database: 'mydb', collection: 'users');

      expect(provider.documents.length, 1);
      expect(provider.documents[0].data['_id'], '123');
      expect(provider.totalDocuments, 50);
      expect(provider.totalPages, 3); // 50/20 = 2.5 -> 3
      expect(provider.currentPage, 1);
      expect(provider.hasMore, isTrue);
      expect(provider.selectedDatabase, 'mydb');
      expect(provider.selectedCollection, 'users');
    });

    test('loadDocuments with filter applies filter', () async {
      fakeRepository.lastCountAnswer = 5;
      fakeRepository.lastDocsAnswer = [makeDoc('abc')];

      // First load to set selectedDatabase and selectedCollection
      await provider.loadDocuments(database: 'mydb', collection: 'users');
      expect(provider.documents.length, 1);

      // Now change filter and reload
      provider.setFilter({'status': 'active'});
      await provider.applyFilterAndReload();

      expect(provider.documents.length, 1);
      expect(fakeRepository.lastFilter, {'status': 'active'});
    });

    test('loadNextPage does nothing if at last page', () async {
      fakeRepository.lastCountAnswer = 10;
      fakeRepository.lastDocsAnswer = [makeDoc('1')];

      await provider.loadDocuments(database: 'mydb', collection: 'users');
      expect(provider.hasMore, isFalse);
      await provider.loadNextPage(); // no-op
      expect(provider.currentPage, 1);
    });

    test('loadNextPage loads second page', () async {
      fakeRepository.lastCountAnswer = 40;
      fakeRepository.lastDocsAnswer = [makeDoc('1')];

      await provider.loadDocuments(database: 'mydb', collection: 'users');
      expect(provider.documents.length, 1);
      expect(provider.documents[0].data['_id'], '1');
      expect(provider.hasMore, isTrue);

      // Simulate second page returning different docs
      fakeRepository.lastDocsAnswer = [makeDoc('2')];
      await provider.loadNextPage();

      expect(provider.documents.length, 2);
      expect(provider.documents[1].data['_id'], '2');
      expect(provider.currentPage, 2);
    });

    test('refresh resets pagination and reloads', () async {
      fakeRepository.lastCountAnswer = 1;
      fakeRepository.lastDocsAnswer = [makeDoc('3')];

      await provider.loadDocuments(database: 'mydb', collection: 'users');
      expect(provider.currentPage, 1);

      await provider.refresh();

      expect(provider.currentPage, 1);
      expect(provider.documents, isNotEmpty);
      expect(provider.documents[0].data['_id'], '3');
    });

    test('deleteDocument removes from local list', () async {
      final docToDelete = makeDoc('xyz');
      provider.documents.add(docToDelete);

      await provider.deleteDocument(docToDelete);

      expect(provider.documents, isEmpty);
    });

    test('deleteDocument sets error on failure', () async {
      final doc = makeDoc('xyz');
      provider.documents.add(doc);

      fakeRepository.shouldThrow = true;
      fakeRepository.throwError = 'Unauthorized';

      await provider.deleteDocument(doc);

      expect(provider.error, contains('Unauthorized'));
    });

    test('clearDocuments resets all state', () async {
      fakeRepository.lastCountAnswer = 1;
      fakeRepository.lastDocsAnswer = [makeDoc('abc')];
      await provider.loadDocuments(database: 'mydb', collection: 'users');

      provider.clearDocuments();

      expect(provider.documents, isEmpty);
      expect(provider.selectedDatabase, isNull);
      expect(provider.selectedCollection, isNull);
      expect(provider.currentPage, 0);
      expect(provider.totalDocuments, 0);
      expect(provider.error, isNull);
    });

    test('loadDocuments sets error on failure', () async {
      fakeRepository.shouldThrow = true;
      fakeRepository.throwError = 'Connection lost';

      await provider.loadDocuments(database: 'mydb', collection: 'users');

      expect(provider.documents, isEmpty);
      expect(provider.error, contains('Connection lost'));
    });
  });
}
