import 'dart:io';
import 'dart:developer';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

/// Simple HTTP Server for serving Apple Wallet passes
///
/// This server serves .pkpass files so they can be accessed via QR codes
/// For production, use a proper web server like Nginx or Apache
class PassServer {
  static HttpServer? _server;
  static final int _port = 8080;
  static final String _baseUrl = 'http://localhost:$_port';

  /// Start the pass server
  static Future<String> startServer() async {
    try {
      if (_server != null) {
        log('🔄 Pass server already running on port $_port');
        return _baseUrl;
      }

      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
      log('🚀 Pass server started on $_baseUrl');

      // Handle requests
      _server!.listen((HttpRequest request) {
        _handleRequest(request);
      });

      return _baseUrl;
    } catch (e) {
      log('❌ Error starting pass server: $e');
      rethrow;
    }
  }

  /// Stop the pass server
  static Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      log('🛑 Pass server stopped');
    }
  }

  /// Handle HTTP requests
  static void _handleRequest(HttpRequest request) {
    try {
      final uri = request.uri;
      log('📥 Request: ${request.method} ${uri.path}');

      if (uri.path.startsWith('/passes/') && uri.path.endsWith('.pkpass')) {
        _servePassFile(request);
      } else if (uri.path == '/') {
        _serveIndexPage(request);
      } else {
        _serve404(request);
      }
    } catch (e) {
      log('❌ Error handling request: $e');
      _serve500(request);
    }
  }

  /// Serve .pkpass files
  static void _servePassFile(HttpRequest request) async {
    try {
      final uri = request.uri;
      final passId = uri.path.split('/').last.replaceAll('.pkpass', '');

      // Look for the pass file in the app's documents directory
      final documentsDir = await _getDocumentsDirectory();
      final passFile = File('${documentsDir.path}/$passId.pkpass');

      if (await passFile.exists()) {
        final passBytes = await passFile.readAsBytes();

        request.response
          ..statusCode = 200
          ..headers.set('Content-Type', 'application/vnd.apple.pkpass')
          ..headers.set('Content-Disposition', 'attachment; filename="$passId.pkpass"')
          ..headers.set('Content-Length', passBytes.length)
          ..add(passBytes);

        await request.response.close();
        log('✅ Served pass file: $passId.pkpass');
      } else {
        _serve404(request);
      }
    } catch (e) {
      log('❌ Error serving pass file: $e');
      _serve500(request);
    }
  }

  /// Serve index page
  static void _serveIndexPage(HttpRequest request) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Apple Wallet Pass Server</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
    <h1>🍎 Apple Wallet Pass Server</h1>
    <p>Server is running on port $_port</p>
    <p>Pass files are served at: <code>/passes/{passId}.pkpass</code></p>
    <p>Example: <a href="/passes/example.pkpass">/passes/example.pkpass</a></p>
</body>
</html>
    ''';

    request.response
      ..statusCode = 200
      ..headers.set('Content-Type', 'text/html')
      ..write(html);
    request.response.close();
  }

  /// Serve 404 error
  static void _serve404(HttpRequest request) {
    request.response
      ..statusCode = 404
      ..headers.set('Content-Type', 'text/plain')
      ..write('Pass not found');
    request.response.close();
  }

  /// Serve 500 error
  static void _serve500(HttpRequest request) {
    request.response
      ..statusCode = 500
      ..headers.set('Content-Type', 'text/plain')
      ..write('Internal server error');
    request.response.close();
  }

  /// Get documents directory
  static Future<Directory> _getDocumentsDirectory() async {
    // Use the same path as the Apple Wallet service
    final documentsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${documentsDir.path}/passes');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Get server URL
  static String get serverUrl => _baseUrl;

  /// Check if server is running
  static bool get isRunning => _server != null;
}
