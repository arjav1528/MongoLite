import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/empty_state.dart';
import '../providers/document_provider.dart';
import 'document_card.dart';

class DocumentList extends StatefulWidget {
  final String databaseName;
  final String collectionName;

  const DocumentList({super.key, required this.databaseName, required this.collectionName});

  @override
  State<DocumentList> createState() => _DocumentListState();
}

class _DocumentListState extends State<DocumentList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200) {
        context.read<DocumentProvider>().loadNextPage();
      }
    }
  }

  Future<void> _loadInitial() async {
    context.read<DocumentProvider>().loadDocuments(
          database: widget.databaseName,
          collection: widget.collectionName,
          reset: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DocumentProvider>().refresh(),
      child: Consumer<DocumentProvider>(
        builder: (context, provider, _) {
          // Loading state
          if (provider.isLoading && provider.documents.isEmpty) {
            return const LoadingIndicator();
          }

          // Error state
          if (provider.error != null && provider.documents.isEmpty) {
            return SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Text(provider.error!, style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadInitial, child: const Text('Retry')),
                    ],
                  ),
                ),
              ),
            );
          }

          // Empty state
          if (provider.documents.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox,
              message: 'No documents found',
              subtitle: 'Try adjusting your query or add a new document',
            );
          }

          // Document list
          final count = provider.documents.length;
          final showLoadMore = provider.hasMore && !provider.isLoading;

          return ListView.builder(
            controller: _scrollController,
            itemCount: count + (showLoadMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == count) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final doc = provider.documents[index];
              return DocumentCard(
                document: doc,
                onDelete: () => provider.deleteDocument(doc),
                onRefresh: () => context.read<DocumentProvider>().refresh(),
              );
            },
          );
        },
      ),
    );
  }
}
