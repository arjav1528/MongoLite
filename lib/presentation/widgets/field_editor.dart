import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/config/app_theme.dart';
import '../../core/utils/json_utils.dart';

/// Type-aware field editor that dispatches to the correct UI based on value type.
class FieldEditor extends StatelessWidget {
  final String keyName;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final bool readOnly;

  const FieldEditor({
    super.key,
    required this.keyName,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (keyName == '_id') {
      return _buildReadOnlyField(keyName, value, readOnly: true);
    }

    final v = value;

    if (v is String) {
      return _buildFieldWrapper(keyName, 'String', const Color(0xFFA5D6A7), () {
        return _StringFieldEditor(value: v, onChanged: onChanged, readOnly: readOnly);
      });
    } else if (v is int) {
      return _buildFieldWrapper(keyName, 'Int', const Color(0xFF90CAF9), () {
        return _NumberFieldEditor(value: v, onChanged: onChanged, readOnly: readOnly);
      });
    } else if (v is double) {
      return _buildFieldWrapper(keyName, 'Double', const Color(0xFF90CAF9), () {
        return _NumberFieldEditor(value: v, onChanged: onChanged, readOnly: readOnly);
      });
    } else if (v is bool) {
      return _buildFieldWrapper(keyName, 'Bool', const Color(0xFFFFAB91), () {
        return _BoolFieldEditor(value: v, onChanged: onChanged, readOnly: readOnly);
      });
    } else if (v is List) {
      return _buildFieldWrapper(keyName, 'Array (${v.length})', const Color(0xFFFFF59D), () {
        return ArrayFieldEditor(value: v, onChanged: onChanged, readOnly: readOnly);
      });
    } else if (v is Map) {
      return _buildFieldWrapper(keyName, 'Object', const Color(0xFFCE93D8), () {
        return _MapFieldEditor(value: v, onChanged: onChanged, readOnly: readOnly);
      });
    } else {
      return _buildFieldWrapper(keyName, 'Null', Colors.white54, () {
        return _NullFieldEditor(onChanged: onChanged, readOnly: readOnly);
      });
    }
  }

  Widget _buildFieldWrapper(
    String name,
    String typeLabel,
    Color typeColor,
    Widget Function() editorBuilder,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.primaryGreen,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: typeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: typeColor.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            editorBuilder(),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String name, dynamic value, {required bool readOnly}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.lock_outline, size: 12, color: Colors.white38),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              value?.toString() ?? 'null',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple string field editor.
class _StringFieldEditor extends StatefulWidget {
  final String value;
  final ValueChanged<dynamic> onChanged;
  final bool readOnly;

  const _StringFieldEditor({required this.value, required this.onChanged, this.readOnly = false});

  @override
  State<_StringFieldEditor> createState() => _StringFieldEditorState();
}

class _StringFieldEditorState extends State<_StringFieldEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      readOnly: widget.readOnly,
      maxLines: (widget.value.length > 40) ? 4 : null,
      style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 14),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onChanged: (text) => widget.onChanged(text),
    );
  }
}

/// Number field editor (int or double).
class _NumberFieldEditor extends StatefulWidget {
  final num value;
  final ValueChanged<dynamic> onChanged;
  final bool readOnly;

  const _NumberFieldEditor({required this.value, required this.onChanged, this.readOnly = false});

  @override
  State<_NumberFieldEditor> createState() => _NumberFieldEditorState();
}

class _NumberFieldEditorState extends State<_NumberFieldEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    if (widget.readOnly) return;
    if (widget.value is int) {
      final parsed = int.tryParse(text);
      if (parsed != null) widget.onChanged(parsed);
    } else {
      final parsed = double.tryParse(text);
      if (parsed != null) widget.onChanged(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      readOnly: widget.readOnly,
      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
      style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 14),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onChanged: _onChanged,
    );
  }
}

/// Boolean field editor with a Switch.
class _BoolFieldEditor extends StatelessWidget {
  final bool value;
  final ValueChanged<dynamic> onChanged;
  final bool readOnly;

  const _BoolFieldEditor({required this.value, required this.onChanged, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: readOnly ? null : (v) => onChanged(v),
          activeColor: AppTheme.primaryGreen,
        ),
        const SizedBox(width: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// MongoDB Compass-style array editor with row-per-item UI.
class ArrayFieldEditor extends StatefulWidget {
  final List value;
  final ValueChanged<dynamic> onChanged;
  final bool readOnly;

  const ArrayFieldEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  State<ArrayFieldEditor> createState() => _ArrayFieldEditorState();
}

class _ArrayFieldEditorState extends State<ArrayFieldEditor> {
  /// Mutable list of items that back the form state.
  final List<_ArrayItem> _items = [];

  @override
  void initState() {
    super.initState();
    for (final v in widget.value) {
      _items.add(_ArrayItem(value: v));
    }
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _notifyChange() {
    final list = _items.map((item) => item.serialize()).toList();
    widget.onChanged(list);
  }

  void _addItem() {
    if (widget.readOnly) return;
    _items.add(_ArrayItem(value: ''));
    _notifyChange();
    setState(() {});
  }

  void _removeItem(int index) {
    if (widget.readOnly) return;
    if (index >= 0 && index < _items.length) {
      _items[index].dispose();
      _items.removeAt(index);
      _notifyChange();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Column(
        children: [
          _buildEmptyState(),
          if (!widget.readOnly) _buildAddButton(),
        ],
      );
    }

    return Column(
      children: [
        for (int i = 0; i < _items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildItemRow(i),
          ),
        if (!widget.readOnly) _buildAddButton(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: const Text(
        'Empty array',
        style: TextStyle(fontSize: 12, color: Colors.white38, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Index label
        SizedBox(
          width: 24,
          child: Text(
            '$index',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white30,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 4),

        // Type chip
        if (!item.isComplex)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _typeColor(item.value).withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              _typeLabel(item.value),
              style: TextStyle(
                fontSize: 8,
                color: _typeColor(item.value).withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        const SizedBox(width: 6),

        // Editor input
        Expanded(
          child: _buildItemInput(item, index),
        ),

        // Delete button
        if (!widget.readOnly) ...[
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _removeItem(index),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItemInput(_ArrayItem item, int index) {
    // Simple scalar types: inline TextField (or Switch for bools)
    if (item.value is String) {
      return TextField(
        controller: item.controller,
        readOnly: widget.readOnly,
        style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 13),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          filled: true,
          fillColor: Colors.white.withOpacity(0.02),
        ),
        onChanged: (text) {
          if (!widget.readOnly) {
            item.value = text;
            _notifyChange();
          }
        },
      );
    }

    if (item.value is int || item.value is double) {
      return TextField(
        controller: item.controller!,
        readOnly: widget.readOnly,
        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
        style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 13),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          filled: true,
          fillColor: Colors.white.withOpacity(0.02),
        ),
        onChanged: (text) {
          if (widget.readOnly) return;
          if (item.value is int) {
            final parsed = int.tryParse(text);
            if (parsed != null) {
              item.value = parsed;
              _notifyChange();
            }
          } else {
            final parsed = double.tryParse(text);
            if (parsed != null) {
              item.value = parsed;
              _notifyChange();
            }
          }
        },
      );
    }

    if (item.value is bool) {
      return Row(
        children: [
          Switch(
            value: item.value as bool,
            onChanged: widget.readOnly
                ? null
                : (v) {
                    item.value = v;
                    _notifyChange();
                    setState(() {});
                  },
            activeColor: AppTheme.primaryGreen,
          ),
          Text(
            item.value.toString(),
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    // Complex types: JSON text editor
    return TextField(
      controller: item.controller,
      readOnly: widget.readOnly,
      maxLines: 5,
      style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 11),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
      ),
      onChanged: (text) async {
        if (widget.readOnly) return;
        try {
          final parsed = jsonDecode(text);
          item.value = parsed;
          _notifyChange();
        } catch (_) {}
      },
    );
  }

  Widget _buildAddButton() {
    return TextButton.icon(
      onPressed: _addItem,
      icon: const Icon(Icons.add, size: 14, color: AppTheme.primaryGreen),
      label: const Text(
        'Add Item',
        style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Color _typeColor(dynamic value) {
    if (value is String) return const Color(0xFFA5D6A7);
    if (value is int) return const Color(0xFF90CAF9);
    if (value is double) return const Color(0xFF90CAF9);
    if (value is bool) return const Color(0xFFFFAB91);
    if (value is Map) return const Color(0xFFCE93D8);
    if (value is List) return const Color(0xFFFFF59D);
    if (value == null) return Colors.white54;
    return Colors.white54;
  }

  String _typeLabel(dynamic value) {
    if (value is String) return 'String';
    if (value is int) return 'Int';
    if (value is double) return 'Double';
    if (value is bool) return 'Bool';
    if (value is Map) return 'Object';
    if (value is List) return 'Array';
    if (value == null) return 'Null';
    return 'Unknown';
  }
}

/// Single mutable item inside an array editor.
class _ArrayItem {
  dynamic value;
  TextEditingController? controller;

  _ArrayItem({required this.value}) {
    if (value is String || value is Map || value is List) {
      controller = TextEditingController(
        text: value is String
            ? value
            : value is Map
                ? JsonUtils.encodeMongoDocumentPretty(
                    Map<String, dynamic>.from(value as Map),
                  )
                : JsonUtils.encodeMongoListPretty(value as List<dynamic>),
      );
    } else if (value is num) {
      controller = TextEditingController(text: value.toString());
    }
  }

  void dispose() {
    controller?.dispose();
  }

  bool get isComplex => value is Map || value is List;

  dynamic serialize() {
    if (controller != null && (value is String || value is Map || value is List)) {
      if (value is Map || value is List) {
        try {
          return jsonDecode(controller!.text);
        } catch (_) {
          return value;
        }
      }
      return controller!.text;
    }
    return value;
  }
}

/// Map field editor — shows JSON text in a multiline editor.
class _MapFieldEditor extends StatefulWidget {
  final Map value;
  final ValueChanged<dynamic> onChanged;
  final bool readOnly;

  const _MapFieldEditor({required this.value, required this.onChanged, this.readOnly = false});

  @override
  State<_MapFieldEditor> createState() => _MapFieldEditorState();
}

class _MapFieldEditorState extends State<_MapFieldEditor> {
  late final TextEditingController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: JsonUtils.encodeMongoDocumentPretty(
        Map<String, dynamic>.from(widget.value),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      readOnly: widget.readOnly,
      maxLines: 8,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 13),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderSide: _hasError
              ? const BorderSide(color: Colors.red)
              : BorderSide.none,
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        errorText: _hasError ? 'Invalid JSON' : null,
      ),
      onChanged: (text) {
        if (widget.readOnly) return;
        try {
          final parsed = jsonDecode(text);
          if (parsed is Map) {
            _hasError = false;
            widget.onChanged(parsed);
          }
        } catch (_) {
          _hasError = true;
        }
        if (mounted) setState(() {});
      },
    );
  }
}

/// Null value display.
class _NullFieldEditor extends StatelessWidget {
  final ValueChanged<dynamic> onChanged;
  final bool readOnly;

  const _NullFieldEditor({required this.onChanged, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'null',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: Colors.white54,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
