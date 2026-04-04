import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/json_utils.dart';
import '../../core/config/app_theme.dart';
import '../../domain/models/mongo_document.dart';
import '../screens/document_detail_screen.dart';
import '../screens/document_edit_screen.dart';

class DocumentCard extends StatelessWidget {
  final MongoDocument document;
  final VoidCallback? onDelete;
  final VoidCallback? onRefresh;

  const DocumentCard({super.key, required this.document, this.onDelete, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final id = document.id?.toString() ?? 'no _id';
    final idPreview = id.length > 30 ? '${id.substring(0, 30)}...' : id;

    final fields = document.data.entries
        .take(3)
        .map((e) => '${e.key}: ${JsonUtils.truncateValue(e.value)}')
        .join('\n');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => _viewDocument(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description, size: 18, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '_id: $idPreview',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  _buildPopupMenu(context),
                ],
              ),
              if (document.data.length > 1) ...[
                const SizedBox(height: 8),
                Text(
                  fields,
                  style: TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'monospace'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _viewDocument(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: document)),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'view', child: Text('View')),
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'copy', child: Text('Copy JSON')),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
      onSelected: (value) => _handleAction(context, value),
    );
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    switch (action) {
      case 'view':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: document)),
        );
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DocumentEditScreen(document: document)),
        ).then((_) => onRefresh?.call());
        break;
      case 'copy':
        final json = JsonEncoder.withIndent('  ').convert(document.data);
        await Clipboard.setData(ClipboardData(text: json));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copied to clipboard')),
          );
        }
        break;
      case 'delete':
        final confirmed = await _showDeleteDialog(context);
        if (confirmed) {
          onDelete?.call();
        }
        break;
    }
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Color(0xFF2C2D30),
            title: const Text('Delete Document'),
            content: const Text('Are you sure you want to delete this document?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
