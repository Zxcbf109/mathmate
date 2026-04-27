import 'package:flutter/material.dart';
import 'package:mathmate/services/local_geogebra_server.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GeogebraPage extends StatefulWidget {
  final String appName;
  final String? initialExpression;

  const GeogebraPage({
    super.key,
    this.appName = 'graphing',
    this.initialExpression,
  });

  @override
  State<GeogebraPage> createState() => _GeogebraPageState();
}

class _GeogebraPageState extends State<GeogebraPage> {
  final LocalGeogebraServer _server = LocalGeogebraServer();
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    try {
      final String baseUrl = await _server.start();
      final String url = '$baseUrl?appName=${widget.appName}';

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) {
                setState(() => _loading = false);
              }
              // 注入初始表达式
              if (widget.initialExpression != null &&
                  widget.initialExpression!.isNotEmpty) {
                _setExpression(widget.initialExpression!);
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() {
                  _loading = false;
                  _error = '加载失败: ${error.description}';
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(url));

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '启动失败: $e';
        });
      }
    }
  }

  Future<void> _setExpression(String expr) async {
    if (_controller == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    try {
      await _controller!.runJavaScript(
        "if(window.GeogebraBridge) window.GeogebraBridge.setExpression('$expr');",
      );
    } catch (_) {}
  }

  String get _title {
    switch (widget.appName) {
      case 'classic':
        return '几何画板';
      case '3d':
        return '3D 绘图';
      case 'geometry':
        return '平面几何';
      default:
        return '函数绘图';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                  _loading = true;
                });
                _initWebView();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: <Widget>[
        if (_controller != null)
          WebViewWidget(controller: _controller!),
        if (_loading)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(color: Color(0xFF3F51B5)),
                SizedBox(height: 12),
                Text('GeoGebra 加载中...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
      ],
    );
  }
}
