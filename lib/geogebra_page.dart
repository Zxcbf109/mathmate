import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GeogebraPage extends StatefulWidget {
  final String appName;

  const GeogebraPage({
    super.key,
    this.appName = 'graphing',
  });

  @override
  State<GeogebraPage> createState() => _GeogebraPageState();
}

class _GeogebraPageState extends State<GeogebraPage> {
  WebViewController? _controller;
  bool _loading = true;
  bool _isDesktop = false;

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
  void initState() {
    super.initState();
    _isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    if (!_isDesktop) {
      _initWebView();
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _loading = false;
              });
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'GeometryBridge',
        onMessageReceived: (JavaScriptMessage message) {
          // interactive geometry events
        },
      )
      ..loadFlutterAsset('assets/geometry/index.html');

    if (mounted) setState(() {});
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
    if (_isDesktop) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.desktop_windows, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '交互式几何画板暂不支持桌面端',
              style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 4),
            const Text(
              '请在手机或平板上使用',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: <Widget>[
        if (_controller != null) WebViewWidget(controller: _controller!),
        if (_loading)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(color: Color(0xFF3F51B5)),
                SizedBox(height: 12),
                Text('几何画板加载中...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
      ],
    );
  }
}
