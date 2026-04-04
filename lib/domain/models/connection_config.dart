class ConnectionConfig {
  final String uri;
  final String? alias;
  final DateTime? lastConnected;

  const ConnectionConfig({
    required this.uri,
    this.alias,
    this.lastConnected,
  });

  String get obfuscatedUri {
    final uri = Uri.parse(this.uri);
    if (uri.userInfo.isEmpty) return this.uri;
    final parts = uri.userInfo.split(':');
    return uri.replace(userInfo: '${parts[0]}:****').toString();
  }

  ConnectionConfig copyWith({String? uri, String? alias}) {
    return ConnectionConfig(
      uri: uri ?? this.uri,
      alias: alias ?? this.alias,
    );
  }
}
