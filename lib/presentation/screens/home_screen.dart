import 'package:flutter/material.dart';

import '../../core/widgets/loading_indicator.dart';
import '../../presentation/providers/connection_provider.dart';
import '../../presentation/providers/database_provider.dart';
import '../../presentation/providers/document_provider.dart';
import '../../presentation/widgets/database_tree_item.dart';
import '../../presentation/widgets/document_list.dart';
import '../../core/widgets/empty_state.dart';
import 'connection_screen.dart';
import 'query_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCollectionName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DatabaseProvider>().loadDatabases();
    });
  }

  void _closeDrawer() => Navigator.pop(context);

  void _onCollectionSelected() {
    _closeDrawer();
    setState(() {
      _selectedCollectionName = context.read<DocumentProvider>().selectedCollection;
    });
  }

  void _disconnect() {
    context.read<ConnectionProvider>().disconnect();
    context.read<DatabaseProvider>().clearData();
    context.read<DocumentProvider>().clearDocuments();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ConnectionScreen()),
        (route) => false,
      );
    });
  }

  void _openQuery() {
    if (_selectedCollectionName != null && context.read<DocumentProvider>().selectedDatabase != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QueryScreen(
            databaseName: context.read<DocumentProvider>().selectedDatabase!,
            collectionName: _selectedCollectionName!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          docProvider.selectedCollection != null
              ? '${docProvider.selectedDatabase}.${docProvider.selectedCollection}'
              : 'MongoLite',
        ),
        actions: [
          if (docProvider.selectedCollection != null)
            IconButton(icon: const Icon(Icons.search), onPressed: _openQuery),
          IconButton(icon: const Icon(Icons.power_settings_new), onPressed: _disconnect),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
      floatingActionButton: docProvider.selectedCollection != null
          ? FloatingActionButton(
              onPressed: () => _showAddDocumentDialog(),
              child: const Icon(Icons.add),
              tooltip: 'Add document',
            )
          : null,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Consumer<ConnectionProvider>(
              builder: (context, conn, _) => ListTile(
                leading: const Icon(Icons.cloud_done, color: AppTheme.primaryGreen),
                title: const Text('Connected'),
                subtitle: Text(conn.obfuscatedUri ?? ''),
                trailing: const Icon(Icons.keyboard_arrow_right),
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Databases', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(child: _buildDatabaseTree()),
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseTree() {
    return Consumer<DatabaseProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.databases.isEmpty) {
          return const LoadingIndicator();
        }
        if (provider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(provider.error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          );
        }
        if (provider.databases.isEmpty) {
          return const Center(child: Text('No databases found', style: TextStyle(color: Colors.white38)));
        }
        return ListView.builder(
          itemCount: provider.databases.length,
          itemBuilder: (context, index) {
            final db = provider.databases[index];
            return DatabaseTreeItem(database: db, onCollectionSelected: _onCollectionSelected);
          },
        );
      },
    );
  }

  Widget _buildBody() {
    final docProvider = context.watch<DocumentProvider>();
    if (docProvider.selectedCollection == null) {
      return const EmptyState(
        icon: Icons.keyboard_arrow_left,
        message: 'Select a collection',
        subtitle: 'Open the drawer to browse databases and collections',
      );
    }
    return DocumentList(
      databaseName: docProvider.selectedDatabase!,
      collectionName: docProvider.selectedCollection!,
    );
  }

  void _showAddDocumentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: '{\n  \n}');
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2D30),
          title: const Text('Add Document'),
          content: SizedBox(
            width: 300,
            child: TextField(
              controller: controller,
              maxLines: 12,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                hintText: '{ "field": "value" }',
                hintStyle: TextStyle(fontFamily: 'monospace', color: Colors.white38),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                // document insertion - handled via document edit flow or direct JSON parse
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add document feature coming soon')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
