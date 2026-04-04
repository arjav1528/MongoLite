import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_theme.dart';
import 'data/services/mongo_connection_service.dart';
import 'data/services/secure_storage_service.dart';
import 'data/repositories/mongo_repository.dart';
import 'presentation/providers/connection_provider.dart';
import 'presentation/providers/database_provider.dart';
import 'presentation/providers/document_provider.dart';
import 'presentation/screens/connection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MongoLiteApp());
}

class MongoLiteApp extends StatelessWidget {
  const MongoLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MongoConnectionService>(
          create: (_) => MongoConnectionService(),
        ),
        Provider<SecureStorageService>(
          create: (_) => SecureStorageService(),
        ),
        Provider<MongoRepository>(
          create: (ctx) => MongoRepository(ctx.read<MongoConnectionService>()),
        ),
        ChangeNotifierProvider<ConnectionProvider>(
          create: (ctx) => ConnectionProvider(
            mongoService: ctx.read<MongoConnectionService>(),
            storageService: ctx.read<SecureStorageService>(),
          ),
        ),
        ChangeNotifierProvider<DatabaseProvider>(
          create: (ctx) => DatabaseProvider(
            repository: ctx.read<MongoRepository>(),
          ),
        ),
        ChangeNotifierProvider<DocumentProvider>(
          create: (ctx) => DocumentProvider(
            repository: ctx.read<MongoRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'MongoLite',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const ConnectionScreen(),
      ),
    );
  }
}
