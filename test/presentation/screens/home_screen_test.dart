import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:mongolite/data/repositories/mongo_repository.dart';
import 'package:mongolite/data/services/mongo_connection_service.dart';
import 'package:mongolite/data/services/secure_storage_service.dart';
import 'package:mongolite/presentation/providers/connection_provider.dart';
import 'package:mongolite/presentation/providers/database_provider.dart';
import 'package:mongolite/presentation/providers/document_provider.dart';
import 'package:mongolite/presentation/screens/home_screen.dart';

import 'home_screen_test.mocks.dart';

@GenerateMocks([MongoConnectionService, MongoRepository])
class FakeSecureStorage extends Fake implements SecureStorageService {
  String? _savedUri;
  @override
  Future<Map<String, String?>> loadConnectionConfig() async =>
      {'uri': _savedUri, 'alias': null};
  @override
  Future<void> saveConnectionConfig({required String uri, String? alias}) async =>
      _savedUri = uri;
  @override
  Future<bool> hasSavedConnection() async => _savedUri != null;
  @override
  Future<void> clearConnectionConfig() async => _savedUri = null;
}

class FakeConnectionService extends Fake implements MongoConnectionService {
  @override
  Future<void> connect(String uri) async {}
  @override
  bool get isConnected => false;
}

void main() {
  group('HomeScreen', () {
    testWidgets('shows MongoLite when no collection selected', (tester) async {
      final mockRepo = MockMongoRepository();
      final connProvider = ConnectionProvider(
        mongoService: FakeConnectionService(),
        storageService: FakeSecureStorage(),
      );
      final dbProvider = DatabaseProvider(repository: mockRepo);
      final docProvider = DocumentProvider(repository: mockRepo);

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<MongoConnectionService>(create: (_) => FakeConnectionService()),
          Provider<SecureStorageService>(create: (_) => FakeSecureStorage()),
          Provider<MongoRepository>(create: (_) => mockRepo),
          ChangeNotifierProvider.value(value: connProvider),
          ChangeNotifierProvider.value(value: dbProvider),
          ChangeNotifierProvider.value(value: docProvider),
        ],
        child: MaterialApp(
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Select a collection'), findsOneWidget);
      expect(find.textContaining('Open the drawer'), findsOneWidget);
    });

    testWidgets('shows collection name in AppBar after selection', (tester) async {
      final mockRepo = MockMongoRepository();
      final connProvider = ConnectionProvider(
        mongoService: FakeConnectionService(),
        storageService: FakeSecureStorage(),
      );
      final dbProvider = DatabaseProvider(repository: mockRepo);
      final docProvider = DocumentProvider(repository: mockRepo);

      when(mockRepo.countDocuments(
        database: 'mydb', collection: 'users', filter: null,
      )).thenAnswer((_) async => 0);
      when(mockRepo.getDocuments(
        database: 'mydb', collection: 'users', filter: null,
        skip: 0, limit: 20,
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<MongoConnectionService>(create: (_) => FakeConnectionService()),
          Provider<SecureStorageService>(create: (_) => FakeSecureStorage()),
          Provider<MongoRepository>(create: (_) => mockRepo),
          ChangeNotifierProvider.value(value: connProvider),
          ChangeNotifierProvider.value(value: dbProvider),
          ChangeNotifierProvider.value(value: docProvider),
        ],
        child: MaterialApp(
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
        ),
      ));
      await tester.pumpAndSettle();

      await docProvider.loadDocuments(database: 'mydb', collection: 'users');
      await tester.pumpAndSettle();

      expect(find.text('mydb.users'), findsOneWidget);
    });

    testWidgets('shows search icon when collection selected', (tester) async {
      final mockRepo = MockMongoRepository();
      final connProvider = ConnectionProvider(
        mongoService: FakeConnectionService(),
        storageService: FakeSecureStorage(),
      );
      final dbProvider = DatabaseProvider(repository: mockRepo);
      final docProvider = DocumentProvider(repository: mockRepo);

      when(mockRepo.countDocuments(
        database: 'db', collection: 'col', filter: null,
      )).thenAnswer((_) async => 0);
      when(mockRepo.getDocuments(
        database: 'db', collection: 'col', filter: null,
        skip: 0, limit: 20,
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<MongoConnectionService>(create: (_) => FakeConnectionService()),
          Provider<SecureStorageService>(create: (_) => FakeSecureStorage()),
          Provider<MongoRepository>(create: (_) => mockRepo),
          ChangeNotifierProvider.value(value: connProvider),
          ChangeNotifierProvider.value(value: dbProvider),
          ChangeNotifierProvider.value(value: docProvider),
        ],
        child: MaterialApp(
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
        ),
      ));
      await tester.pumpAndSettle();

      await docProvider.loadDocuments(database: 'db', collection: 'col');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows floating action button when collection selected', (tester) async {
      final mockRepo = MockMongoRepository();
      final connProvider = ConnectionProvider(
        mongoService: FakeConnectionService(),
        storageService: FakeSecureStorage(),
      );
      final dbProvider = DatabaseProvider(repository: mockRepo);
      final docProvider = DocumentProvider(repository: mockRepo);

      when(mockRepo.countDocuments(
        database: 'db', collection: 'col', filter: null,
      )).thenAnswer((_) async => 0);
      when(mockRepo.getDocuments(
        database: 'db', collection: 'col', filter: null,
        skip: 0, limit: 20,
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<MongoConnectionService>(create: (_) => FakeConnectionService()),
          Provider<SecureStorageService>(create: (_) => FakeSecureStorage()),
          Provider<MongoRepository>(create: (_) => mockRepo),
          ChangeNotifierProvider.value(value: connProvider),
          ChangeNotifierProvider.value(value: dbProvider),
          ChangeNotifierProvider.value(value: docProvider),
        ],
        child: MaterialApp(
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
        ),
      ));
      await tester.pumpAndSettle();

      await docProvider.loadDocuments(database: 'db', collection: 'col');
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
