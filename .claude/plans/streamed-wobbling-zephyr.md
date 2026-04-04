# MongoDB PhoneCompanion - Implementation Plan

## Context

Building a Flutter-based MongoDB client app from scratch — a phone-friendly version of MongoDB Compass. Users enter a connection string, then browse databases/collections and view/edit documents. Targets **both iOS & Android** with **full CRUD** support. The project directory (`/Users/arjavpatel/Desktop/MongoDB-PhoneCompanion/`) is currently empty (only `firebase-debug.log`).

Flutter version: **3.43.0-0.3.pre** (Dart 3.12.0 equivalent).

---

## Architecture

**State Management**: Provider (ChangeNotifier)
**MongoDB Driver**: `mongodb_dart` (official Dart driver)
**Secure Storage**: `flutter_secure_storage` (stores connection strings)
**Theme**: Dark-first, MongoDB Compass-inspired with `#00ED64` accent
**UI Pattern**: Drawer for DB/collection tree → body for documents

## Directory Structure

```
lib/
  main.dart
  core/
    config/app_theme.dart
    utils/connection_string_validator.dart
    utils/json_utils.dart
    widgets/ (loading_indicator, empty_state, error_banner)
  data/
    services/mongo_connection_service.dart      # mongodb_dart wrapper
    services/secure_storage_service.dart         # connection persistence
    repositories/mongo_repository.dart           # data access layer
  domain/
    models/ (connection_config, mongo_database, mongo_collection, mongo_document)
    exceptions/mongo_exceptions.dart
  presentation/
    providers/ (connection, database, document providers)
    screens/ (connection, home, document_detail, document_edit, query)
    widgets/ (database_tree_item, document_card, document_list, json_viewer)
```

---

## Implementation Steps

### 1. Project Scaffolding
- Run `flutter create . --project-name mongodb_phone_companion --org com.mongodb` from project root
- Configure `pubspec.yaml` with: `mongodb_dart ^0.10.0`, `provider ^6.1.0`, `flutter_secure_storage ^9.0.0`, `json_annotation ^4.9.0`
- `flutter pub get`
- Create all directories under `lib/`

### 2. Domain Models (5 files)
- `ConnectionConfig` — stores URI, alias, has `obfuscatedUri` getter
- `MongoDatabaseInfo` — name, sizeOnDisk, empty flag
- `MongoCollectionInfo` — databaseName, name, doc count, storage size
- `MongoDocument` — holds raw `Map<String, dynamic>`, exposes `_id`
- Sealed `MongoAppException` class with typed variants (ConnectionFailed, Auth, Timeout, InvalidUri, NotFound)

### 3. Connection String Validator
- Validates `mongodb://` and `mongodb+srv://` schemes, host required, port range check
- Returns `ValidationResult(isValid, error?)`

### 4. Data Layer
- **SecureStorageService** — save/load/clear connection config to keychain
- **MongoConnectionService** — core wrapper around `mongodb_dart`:
  - `connect(uri)`, `disconnect()`
  - `getDatabaseNames()` via `db.admin.listDatabases()`
  - `getCollectionNames(databaseName)` — create new Db scoped to each database
  - `getDocuments()` with pagination (skip/limit), filter, sort
  - `countDocuments()` for pagination totals
  - `insertDocument()`, `updateDocument()`, `deleteDocument()`
  - Internal `_ensureConnected()` guard
- **MongoRepository** — maps raw results to domain models, delegates to service

### 5. Providers (State Management)
- **ConnectionProvider** — manages connect/disconnect state, saves to secure storage, validates input
- **DatabaseProvider** — loads databases & collections, clears on connection change
- **DocumentProvider** — paginated document loading (20 per page), filter support, next page, delete

Provider wiring: `MultiProvider` with `ChangeNotifierProxyProvider` so database/document providers reset when connection changes.

### 6. Theme
- Dark theme as default (Compass-style): `#1C1D1F` bg, `#2C2D30` surface, `#00ED64` accent
- Light theme also available
- Material 3, `ThemeMode.system`

### 7. Screens
- **ConnectionScreen**: Multi-line URI input, real-time validation, connect button, load-saved-connection option, example connection strings help
- **HomeScreen**: Scaffold with Drawer (DB/collection tree via `ExpansionTile`), AppBar with search & disconnect FAB for add document, body shows `DocumentList` when collection selected
- **DocumentDetailScreen**: JSON viewer, copy to clipboard, navigate to edit
- **DocumentEditScreen**: Toggle between form mode (field-by-field) and raw JSON mode (monospace text editor), save/update
- **QueryScreen**: Simple key-value filter builder + raw JSON query mode, runs filter against selected collection

### 8. Shared Widgets
- **DatabaseTreeItem**: `ExpansionTile` that loads collections on expand
- **DocumentCard**: Shows `_id` + field preview + popup menu (view/edit/copy/delete)
- **DocumentList**: Paginated `ListView.builder` with pull-to-refresh, load-more indicator at bottom
- **JsonDocumentViewer**: Collapsible JSON tree (try `flutter_jsonview` package, fallback to custom `ExpansionTile` recursion)

### 9. App Wiring (`main.dart`)
- `MultiProvider` tree: `ConnectionProvider` → `DatabaseProvider` (ProxyProvider) → `DocumentProvider` (ProxyProvider2)
- `MaterialApp` with dark default theme
- Root route: `ConnectionScreen` → `HomeScreen` on successful connect

---

## Verification Plan

1. `flutter pub get` — dependencies resolve cleanly
2. `flutter analyze` — no lint errors or type issues
3. `flutter run` on iOS simulator / Android emulator — app launches, shows connection screen
4. Test connection with a MongoDB Atlas or local instance — verify databases load in drawer
5. Browse collections, load documents with pagination
6. Test CRUD: create a document, edit it, delete it
7. Test query filter on a collection
8. Test disconnect and reconnect

---

## Key Technical Decisions

- **Database switching**: `mongodb_dart.Db` binds to one database in the URI. To switch databases, create a new `Db` with the target database path in the URI.
- **ObjectId handling**: The driver deserializes `_id` as `ObjectId` class. Use raw value for queries, `.toString()` only for display.
- **Pagination**: Default 20 docs per page, max cap of 50, with skip-based pagination.
- **JSON viewer**: Attempt `flutter_jsonview` for Compass-like collapsible tree. If incompatible with Flutter 3.43, custom recursive `ExpansionTile` implementation.
- **iOS simulator** for `flutter_secure_storage` may need keychain setup in build settings.
