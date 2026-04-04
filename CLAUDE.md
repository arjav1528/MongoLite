# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**MongoLite** — a Flutter-based MongoDB client app for phones, modeled after MongoDB Compass. Users enter a connection string, browse databases/collections, and perform full CRUD on documents. Targets iOS & Android.

## Getting Started

```bash
# Scaffold the Flutter project (first time only)
flutter create . --project-name mongolite --org com.mongolite

# Install dependencies
flutter pub get

# Run on simulator/emulator
flutter run

# Analyze code
flutter analyze

# Run tests
flutter test

# Run a specific test
flutter test test/path/to/test_file.dart
```

## Architecture

Clean architecture with Provider for state management:

```
lib/
  core/
    config/app_theme.dart                    # MongoDB Compass-inspired dark theme (#00ED64 accent)
    utils/connection_string_validator.dart   # MongoDB URI validation
    utils/json_utils.dart
    widgets/                                 # Shared: loading, empty, error states
  data/
    services/mongo_connection_service.dart   # Core: mongodb_dart wrapper (connect, disconnect, queries)
    services/secure_storage_service.dart     # Flutter secure keychain for connection strings
    repositories/mongo_repository.dart       # Maps raw data to domain models
  domain/
    models/                                  # Config, Database, Collection, Document
    exceptions/mongo_exceptions.dart         # Sealed exception hierarchy
  presentation/
    providers/                               # ConnectionProvider, DatabaseProvider, DocumentProvider
    screens/                                 # Connection, Home, DocumentDetail, DocumentEdit, Query
    widgets/                                 # TreeItems, Cards, Lists, JSONViewer
```

## Key Decisions

- **State management**: Provider with `MultiProvider` + `ChangeNotifierProxyProvider`
- **MongoDB driver**: `mongo_dart` v0.10.8 (official Dart driver, mobile-only, no web target)
- **`mongo_dart.Db` binds to one database** in the connection string URI. To switch databases, create a new `Db` with the target database path in the URI
- **`_id` handling**: Driver deserializes `_id` as `ObjectId` class. Use raw value for queries, `.toString()` only for display
- **Pagination**: Skip-based, default 20 docs/page, cap at 50
- **Dark theme default**: Compass-style — `#1C1D1F` bg, `#2C2D30` surface, `#00ED64` accent
- **Secure storage**: `flutter_secure_storage` for connection string persistence
- **JSON viewer**: Try `flutter_jsonview` first; fallback to custom recursive `ExpansionTile` implementation

## Git & Commits

- Commit frequently after each logical step (e.g., models → services → providers → screens)
- Use clear, descriptive commit messages following Conventional Commits format: `feat: add connection screen`, `fix: resolve pagination off-by-one`
- Never squash or amend commits. Each commit should represent a meaningful, self-contained change
- Do not use `--no-verify` or `--amend` unless explicitly requested
- Commit before navigating to complex branching in implementation

## Implementation Plan

See `.claude/plans/streamed-wobbling-zephyr.md` for the full implementation plan.

## Flutter Version

Flutter **3.43.0-0.3.pre** (Dart 3.12.0). Dart 3 sealed classes are available.
