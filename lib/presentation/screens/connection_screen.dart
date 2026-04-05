import 'package:flutter/material.dart';

import '../../core/config/app_theme.dart';
import '../../presentation/providers/connection_provider.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final TextEditingController _uriController = TextEditingController();
  bool _hasLoadedSavedConfig = false;

  @override
  void initState() {
    super.initState();
    _uriController.addListener(_onUriChanged);
    _loadSavedConfig();
  }

  void _onUriChanged() => setState(() {});

  Future<void> _loadSavedConfig() async {
    final provider = context.read<ConnectionProvider>();
    await provider.loadSavedConnection();
    if (mounted && provider.config != null) {
      _uriController.text = provider.config!.uri;
      _hasLoadedSavedConfig = true;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _uriController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final uri = _uriController.text.trim().replaceAll(RegExp(r'[\r\n]+'), '');
    if (uri.isEmpty) return;

    final provider = context.read<ConnectionProvider>();
    await provider.connect(uri);

    if (mounted && provider.isConnected) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConnectionProvider>();
    final rawUri = _uriController.text;
    final cleanUri = rawUri.replaceAll(RegExp(r'[\r\n]+'), '');
    final validationError = provider.getValidationError(cleanUri);
    final isValid = validationError == null && rawUri.trim().isNotEmpty;
    final isConnecting = provider.state == ConnectionStateEnum.connecting;
    final hasError = provider.state == ConnectionStateEnum.error;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Title
                const Icon(Icons.storage, size: 64, color: AppTheme.primaryGreen),
                const SizedBox(height: 8),
                const Text(
                  'MongoLite',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'MongoDB Client for Mobile',
                  style: TextStyle(fontSize: 14, color: Colors.white54),
                ),
                const SizedBox(height: 48),

                // Input
                TextField(
                  controller: _uriController,
                  keyboardType: TextInputType.url,
                  maxLines: 3,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Connection String',
                    hintText: 'mongodb://user:pass@host:port/db',
                    hintStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    prefixIcon: const Icon(Icons.link, size: 24),
                    errorText: hasError ? provider.error : validationError,
                  ),
                ),
                const SizedBox(height: 16),

                // Connect Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const ValueKey('connectButton'),
                    onPressed: isValid && !isConnecting ? _connect : null,
                    child: isConnecting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Connect'),
                  ),
                ),

                // Connect again after error
                if (hasError && isValid) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _connect,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Try Again'),
                    ),
                  ),
                ],

                // Load saved connection
                if (_hasLoadedSavedConfig && _uriController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Loaded: ${provider.obfuscatedUri ?? _uriController.text}',
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],

                // Help
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF2C2D30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.help_outline, size: 18, color: Colors.white54),
                          SizedBox(width: 8),
                          Text(
                            'Connection string examples',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildExample('mongodb://localhost:27017/mydb'),
                      _buildExample('mongodb+srv://user:pass@cluster.mongodb.net/mydb'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExample(String example) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        example,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white38),
      ),
    );
  }
}
