import 'package:flutter/material.dart';

import '../../domain/models/mongo_database.dart';
import '../../presentation/providers/database_provider.dart';
import '../../presentation/providers/document_provider.dart';
import 'package:provider/provider.dart';

class DatabaseTreeItem extends StatefulWidget {
  final MongoDatabaseInfo database;
  final VoidCallback onCollectionSelected;

  const DatabaseTreeItem({super.key, required this.database, required this.onCollectionSelected});

  @override
  State<DatabaseTreeItem> createState() => _DatabaseTreeItemState();
}

class _DatabaseTreeItemState extends State<DatabaseTreeItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          leading: const Icon(Icons.storage, size: 20),
          title: Text(widget.database.name),
          tilePadding: const EdgeInsets.only(left: 16, right: 8),
          onExpansionChanged: _onExpand,
          children: _expanded ? [Consumer<DatabaseProvider>(
            builder: (context, provider, _) {
              final collections = provider.collections
                  .where((c) => c.databaseName == widget.database.name)
                  .toList();
              if (collections.isEmpty) {
                return const ListTile(
                  contentPadding: EdgeInsets.only(left: 48),
                  title: Text(
                    'No collections',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.white38),
                  ),
                );
              }
              return Column(
                children: collections.map(_buildCollectionTile).toList(),
              );
            },
          )] : [],
        ),
      ],
    );
  }

  Widget _buildCollectionTile(collection) {
    return Consumer<DocumentProvider>(
      builder: (context, docProvider, _) {
        final isSelected = docProvider.selectedCollection == collection.name &&
            docProvider.selectedDatabase == collection.databaseName;
        return ListTile(
          contentPadding: const EdgeInsets.only(left: 48, right: 8),
          leading: const Icon(Icons.table_chart, size: 18, color: Colors.white54),
          title: Text(collection.name, style: const TextStyle(fontSize: 14)),
          subtitle: Text('${collection.documentCount ?? '?'} docs', style: const TextStyle(fontSize: 11, color: Colors.white38)),
          selected: isSelected,
          onTap: () {
            context.read<DocumentProvider>().loadDocuments(
                  database: collection.databaseName,
                  collection: collection.name,
                  reset: true,
                );
            widget.onCollectionSelected();
          },
        );
      },
    );
  }

  void _onExpand(bool expanded) {
    setState(() => _expanded = expanded);
    if (expanded) {
      context.read<DatabaseProvider>().loadCollections(widget.database.name);
    }
  }
}