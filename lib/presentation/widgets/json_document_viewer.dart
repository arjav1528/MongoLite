import 'package:flutter/material.dart';

import '../../core/utils/json_utils.dart';

class JsonDocumentViewer extends StatelessWidget {
  final Map<String, dynamic> data;

  const JsonDocumentViewer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final formatted = JsonUtils.encodeMongoDocumentPretty(data);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: SelectableText(
          formatted,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
