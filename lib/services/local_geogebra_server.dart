import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

/// 本地 GeoGebra HTTP 服务器
///
/// 将 assets/geogebra/ 下的文件复制到临时目录，启动本地 HTTP 服务器，
/// WebView 通过 http://127.0.0.1:{port}/index.html 加载，
/// 所有相对路径 (deployggb.js, web3d/...) 自动解析正确。
class LocalGeogebraServer {
  static final LocalGeogebraServer _instance = LocalGeogebraServer._();
  factory LocalGeogebraServer() => _instance;
  LocalGeogebraServer._();

  HttpServer? _server;
  String? _serveDir;
  int _port = 0;
  bool _started = false;
  Completer<void>? _copyCompleter;

  /// 需要从 assets 复制的文件列表
  static const _assetFiles = <String>[
    'assets/geogebra/index.html',
    'assets/geogebra/deployggb.js',
    'assets/geogebra/web3d/web3d.nocache.js',
    'assets/geogebra/web3d/0C7057AD68C986E5B1859BFB332A1012.cache.js',
  ];

  int get port => _port;
  String get url => 'http://127.0.0.1:$_port/index.html';

  /// 初始化文件并启动服务器，返回本地 URL
  Future<String> start() async {
    if (_started) return url;

    if (_copyCompleter != null) {
      await _copyCompleter!.future;
      return url;
    }

    _copyCompleter = Completer<void>();

    try {
      await _copyAssetsToTemp();
      await _startServer();
      _started = true;
    } finally {
      _copyCompleter = null;
    }

    return url;
  }

  Future<void> _copyAssetsToTemp() async {
    final tempDir = await getTemporaryDirectory();
    final geogebraDir = Directory('${tempDir.path}/geogebra_assets');
    _serveDir = geogebraDir.path;

    final indexFile = File('${geogebraDir.path}/index.html');
    if (await indexFile.exists()) {
      return;
    }

    await geogebraDir.create(recursive: true);

    for (final assetPath in _assetFiles) {
      try {
        final data = await rootBundle.load(assetPath);
        final relativePath = assetPath.replaceFirst('assets/geogebra/', '');
        final targetFile = File('${geogebraDir.path}/$relativePath');

        await targetFile.parent.create(recursive: true);
        await targetFile.writeAsBytes(data.buffer.asUint8List());
      } catch (e) {
        // 文件不存在时跳过
      }
    }
  }

  Future<void> _startServer() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;

    _server!.listen((HttpRequest request) {
      _handleRequest(request);
    });
  }

  Future<void> _handleRequest(HttpRequest request) async {
    String path = request.uri.path;
    final String? appNameQuery = request.uri.queryParameters['appName'];

    if (path == '/' || path.isEmpty) {
      path = '/index.html';
    }

    final sanitized = path.replaceAll('\\', '/');
    if (sanitized.contains('..')) {
      request.response.statusCode = 403;
      await request.response.close();
      return;
    }

    final filePath = '$_serveDir$sanitized';
    final file = File(filePath);

    if (await file.exists()) {
      try {
        List<int> content = await file.readAsBytes();

        // 动态替换 index.html 中的 appName
        if (sanitized.endsWith('index.html') && appNameQuery != null) {
          String html = String.fromCharCodes(content);
          html = html.replaceFirst('"appName": "graphing"', '"appName": "$appNameQuery"');
          content = html.codeUnits;
        }

        request.response.headers.contentType = _contentType(path);
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Cache-Control', 'max-age=3600');
        request.response.add(content);
      } catch (e) {
        request.response.statusCode = 500;
      }
    } else {
      request.response.statusCode = 404;
    }
    await request.response.close();
  }

  ContentType _contentType(String path) {
    if (path.endsWith('.html')) return ContentType.html;
    if (path.endsWith('.js')) return ContentType('application', 'javascript', charset: 'utf-8');
    if (path.endsWith('.css')) return ContentType('text', 'css', charset: 'utf-8');
    if (path.endsWith('.png')) return ContentType('image', 'png');
    if (path.endsWith('.svg')) return ContentType('image', 'svg+xml');
    if (path.endsWith('.json')) return ContentType('application', 'json');
    return ContentType('application', 'octet-stream');
  }

  /// 停止服务器
  void stop() {
    _server?.close();
    _server = null;
    _started = false;
    _port = 0;
  }
}
