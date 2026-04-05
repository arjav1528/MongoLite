import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/utils/json_utils.dart';
import '../../domain/models/mongo_document.dart';
import '../../presentation/providers/document_provider.dart';
import '../../data/services/mongo_connection_service.dart';

class DocumentEditScreen extends StatefulWidget {
  final MongoDocument document;

  const DocumentEditScreen({super.key, required this.document});

  @override
  State<DocumentEditScreen> createState() => _DocumentEditScreenState();
}

class _DocumentEditScreenState extends State<DocumentEditScreen> {
  late TextEditingController _jsonController;
  bool _isRawMode = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController(
      text: JsonEncoder.withIndent('  ').convert(widget.document.data),
    );
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _jsonController.text.trim();
    final parsed = JsonUtils.tryParse(text);

    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid JSON. Please check your syntax.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final mongoService = context.read<MongoConnectionService>();
      await mongoService.updateDocument(
        databaseName: widget.document.databaseName,
        collectionName: widget.document.collectionName,
        documentId: widget.document.id,
        updates: parsed,
      );

      // ignore: use_build_context_synchronously
      final docProvider = context.read<DocumentProvider>();
      await docProvider.refresh();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document updated successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Document'),
        actions: [
          IconButton(
            icon: Icon(_isRawMode ? Icons.list : Icons.code),
            onPressed: () => setState(() => _isRawMode = !_isRawMode),
            tooltip: _isRawMode ? 'Switch to form view' : 'Switch to raw JSON',
          ),
        ],
      ),
      body: _isRawMode ? _buildRawEditor() : _buildFormEditor(),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSaving ? null : _save,
        backgroundColor: AppTheme.primaryGreen,
        child: _isSaving
            ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            : const Icon(Icons.save, color: Colors.black),
      ),
    );
  }

  Widget _buildRawEditor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _jsonController,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.white70),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: '{ "key": "value" }',
        ),
      ),
    );
  }

  Widget _buildFormEditor() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.document.data.length,
      itemBuilder: (context, index) {
        final entry = widget.document.data.entries.toList()[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildFieldRow(entry.key, entry.value),
        );
      },
    );
  }

  Widget _buildFieldRow(String key, dynamic value) {
    final controller = TextEditingController(text: value?.toString() ?? '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 4),
            Text(
              '${value.runtimeType}',
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: (value?.toString().length ?? 0) > 50 ? 4 : 1,
              style: const TextStyle(fontFamily: 'monospace', color: Colors.white70),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (_) {
                _updateJsonValue(key, controller.text);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateJsonValue(String key, String newValue) {
    try {
      final parsed = jsonDecode(_jsonController.text);
      if (parsed is Map) {
        parsed[key] = newValue;
      }
    } catch (_) {}
  }
}
