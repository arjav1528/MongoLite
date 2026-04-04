import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:mongolite/data/repositories/mongo_repository.dart';
import 'package:mongolite/data/services/mongo_connection_service.dart';
import 'package:mongolite/data/services/secure_storage_service.dart';
import 'package:mongolite/presentation/providers/connection_provider.dart';
import 'package:mongolite/presentation/screens/connection_screen.dart';

class FakeMongoConnectionService extends Fake implements MongoConnectionService {
  bool _connected = false;
  Completer<void>? _pendingConnect;

  void setPendingConnect(Completer<void> completer) => _pendingConnect = completer;

  @override
  Future<void> connect(String uri) async {
    if (_pendingConnect != null) return _pendingConnect!.future;
    _connected = true;
  }

  @override
  bool get isConnected => _connected;

  @override
  Future<void> disconnect() async => _connected = false;
}

class FakeSecureStorageService extends Fake implements SecureStorageService {
  String? savedUri;

  @override
  Future<void> saveConnectionConfig({required String uri, String? alias}) async => savedUri = uri;

  @override
  Future<Map<String, String?>> loadConnectionConfig() async => {'uri': savedUri, 'alias': null};

  @override
  Future<void> clearConnectionConfig() async => savedUri = null;

  @override
  Future<bool> hasSavedConnection() async => savedUri != null;
}

Widget makeTestableWidget({
  required FakeMongoConnectionService mongoService,
  required FakeSecureStorageService storageService,
}) {
  final connProvider = ConnectionProvider(
    mongoService: mongoService,
    storageService: storageService,
  );
  return MultiProvider(
    providers: [
      Provider<MongoConnectionService>(create: (_) => mongoService),
      Provider<SecureStorageService>(create: (_) => storageService),
      Provider<MongoRepository>(create: (_) => FakeMongoRepository()),
      ChangeNotifierProvider.value(value: connProvider),
    ],
    child: MaterialApp(
      home: const ConnectionScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
    ),
  );
}

void main() {
  group('ConnectionScreen', () {
    testWidgets('shows app title and connection input', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          mongoService: FakeMongoConnectionService(),
          storageService: FakeSecureStorageService(),
        ),
      );

      expect(find.text('MongoLite'), findsOneWidget);
      expect(find.text('Connection String'), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
    });

    testWidgets('shows connect button', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          mongoService: FakeMongoConnectionService(),
          storageService: FakeSecureStorageService(),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('shows connection string examples', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          mongoService: FakeMongoConnectionService(),
          storageService: FakeSecureStorageService(),
        ),
      );

      expect(find.text('Connection string examples'), findsOneWidget);
      expect(find.text('mongodb://localhost:27017/mydb'), findsOneWidget);
    });

    testWidgets('disables button while connecting', (tester) async {
      final completer = Completer<void>();
      final service = FakeMongoConnectionService()..setPendingConnect(completer);

      await tester.pumpWidget(
        makeTestableWidget(
          mongoService: service,
          storageService: FakeSecureStorageService(),
        ),
      );

      await tester.enterText(find.byType(TextField), 'mongodb://localhost:27017/testdb');
      await tester.pumpAndSettle();

      // Tap connect - this starts async connection
      await tester.tap(find.byKey(const ValueKey('connectButton')));
      // Let the tap animation and state change propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Button should be disabled while connecting
      final button = tester.widget<ElevatedButton>(find.byKey(const ValueKey('connectButton')));
      expect(button.onPressed, isNull, reason: 'Button should be disabled while connecting');

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('shows validation error on invalid string', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          mongoService: FakeMongoConnectionService(),
          storageService: FakeSecureStorageService(),
        ),
      );

      await tester.enterText(find.byType(TextField), 'not-a-valid-uri');
      await tester.pumpAndSettle();

      final elevatedButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets('loads saved connection on start', (tester) async {
      final storage = FakeSecureStorageService()
        ..savedUri = 'mongodb://localhost:27017/saveddb';

      await tester.pumpWidget(
        makeTestableWidget(
          mongoService: FakeMongoConnectionService(),
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller?.text, isNotEmpty);
    });
  });
}

class FakeMongoRepository extends Fake implements MongoRepository {}
