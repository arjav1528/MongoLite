import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_theme.dart';
import '../../core/utils/json_utils.dart';
import '../widgets/field_editor.dart';
import '../../domain/models/mongo_document.dart';
import '../../presentation/providers/document_provider.dart';
import '../../data/services/mongo_connection_service.dart';

class DocumentEditScreen extends StatefulWidget {
  final MongoDocument document;

  const DocumentEditScreen({super.key, required this.document});

  @override
  State<DocumentEditScreen> createState() => _DocumentEditScreenState();
}

// Key used to retrieve the live document data from the form editor.
final GlobalKey<_FormEditorState> _formEditorKey = GlobalKey<_FormEditorState>();

class _DocumentEditScreenState extends State<DocumentEditScreen> {
  late TextEditingController _jsonController;
  bool _isRawMode = false;
  bool _isSaving = false;

  /// Live document data that both form and raw editors stay in sync with.
  late Map<String, dynamic> _liveData;

  @override
  void initState() {
    super.initState();
    _liveData = JsonUtils.deepCopy(widget.document.data);
    _jsonController = TextEditingController(
      text: JsonUtils.encodeMongoDocumentPretty(_liveData),
    );
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  /// Rebuilds _jsonController from _liveData (used when switching modes).
  void _syncRawEditor() {
    _jsonController.text = JsonUtils.encodeMongoDocumentPretty(_liveData);
  }

  Future<void> _save() async {
    Map<String, dynamic> updates;

    if (_isRawMode) {
      final text = _jsonController.text.trim();
      final parsed = JsonUtils.tryParse(text);
      if (parsed == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid JSON. Please check your syntax.')),
        );
        return;
      }
      updates = parsed;
    } else {
      final formData = _formEditorKey.currentState?.getDocumentData();
      if (formData == null) return;
      updates = formData;
    }

    setState(() => _isSaving = true);

    try {
      final mongoService = context.read<MongoConnectionService>();
      await mongoService.updateDocument(
        databaseName: widget.document.databaseName,
        collectionName: widget.document.collectionName,
        documentId: widget.document.id,
        updates: updates,
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

  void _toggleMode() {
    if (_isRawMode) {
      // Switching to form mode: raw editor text → _liveData → form
      final parsed = JsonUtils.tryParse(_jsonController.text);
      if (parsed != null) _liveData = parsed;
    } else {
      // Switching to raw mode: form state → _liveData → raw controller
      final formData = _formEditorKey.currentState?.getDocumentData();
      if (formData != null) _liveData = formData;
    }
    setState(() => _isRawMode = !_isRawMode);
    if (_isRawMode) _syncRawEditor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Document'),
        actions: [
          IconButton(
            icon: Icon(_isRawMode ? Icons.list : Icons.code),
            onPressed: _toggleMode,
            tooltip: _isRawMode ? 'Switch to form view' : 'Switch to raw JSON',
          ),
        ],
      ),
      body: _isRawMode ? _buildRawEditor() : _FormEditor(
        key: _formEditorKey,
        data: _liveData,
        onEachChange: (newData) {
          _liveData = newData;
        },
      ),
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
        onChanged: (text) {
          // Keep _liveData in sync with what the user types
          final parsed = JsonUtils.tryParse(text);
          if (parsed != null) _liveData = parsed;
        },
      ),
    );
  }
}

/// Persistent form editor for _FormEditorState. Builds a `ListView.builder` of fields.

/// Persistent form editor that owns field state.
class _FormEditor extends StatefulWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onEachChange;

  const _FormEditor({super.key, required this.data, required this.onEachChange});

  @override
  State<_FormEditor> createState() => _FormEditorState();
}

class _FormEditorState extends State<_FormEditor> {
  /// Tracks the current value of each field. Lives across widget rebuilds.
  /// Rebuilding only happens on mode switch; ValueKey(key) handles that.
  late List<MapEntry<String, dynamic>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.data.entries.toList();
  }

  @override
  void didUpdateWidget(_FormEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _entries = widget.data.entries.toList();
    }
  }

  Map<String, dynamic> getDocumentData() {
    final result = <String, dynamic>{};
    for (final e in _entries) {
      result[e.key] = e.value;
    }
    return result;
  }

  void _onFieldChanged(String key, dynamic newValue) {
    final idx = _entries.indexWhere((e) => e.key == key);
    if (idx != -1) {
      _entries[idx] = MapEntry(key, newValue);
      widget.onEachChange(getDocumentData());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FieldEditor(
            key: ValueKey(entry.key),
            keyName: entry.key,
            value: entry.value,
            readOnly: entry.key == '_id',
            onChanged: (newValue) => _onFieldChanged(entry.key, newValue),
          ),
        );
      },
    );
  }
}
