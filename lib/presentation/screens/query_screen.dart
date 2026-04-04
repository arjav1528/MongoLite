import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/utils/json_utils.dart';
import '../../presentation/providers/document_provider.dart';

class QueryScreen extends StatefulWidget {
  final String databaseName;
  final String collectionName;

  const QueryScreen({super.key, required this.databaseName, required this.collectionName});

  @override
  State<QueryScreen> createState() => _QueryScreenState();
}

class _QueryScreenState extends State<QueryScreen> {
  final _queryController = TextEditingController();
  bool _hasResults = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _runQuery() async {
    final text = _queryController.text.trim();
    Map<String, dynamic>? filter;

    if (text.isNotEmpty) {
      filter = JsonUtils.tryParse(text);
      if (filter == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid JSON query. Please check your syntax.')),
        );
        return;
      }
    }

    final provider = context.read<DocumentProvider>();
    provider.setFilter(filter ?? {});
    await provider.applyFilterAndReload();

    if (mounted) {
      setState(() => _hasResults = true);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Query: ${widget.collectionName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter a filter query in MongoDB JSON format',
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _queryController,
              maxLines: 6,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.white70),
              decoration: const InputDecoration(
                hintText: '{ "status": "active", "age": { "\$gt": 18 } }',
                hintStyle: TextStyle(fontFamily: 'monospace', color: Colors.white38),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _runQuery,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run Query'),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Examples', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 8),
                  Text('{ "status": "active" }', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white54)),
                  Text('{ "age": { "\$gte": 21 } }', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white54)),
                  Text('{ "name": /John/ }', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
