import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

import 'package:mathmate/services/local_geogebra_server.dart';

class GeogebraPage extends StatefulWidget {
  final String? initialExpression;

  const GeogebraPage({super.key, this.initialExpression});

  @override
  State<GeogebraPage> createState() => _GeogebraPageState();
}

class _GeogebraPageState extends State<GeogebraPage> {
  // 移动端 (Android/iOS)
  WebViewController? _mobileController;

  // Windows WebView2
  WebviewController? _winController;
  StreamSubscription<dynamic>? _winMessageSubscription;

  final LocalGeogebraServer _localServer = LocalGeogebraServer();

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isReady = false;

  bool _isDesktopFallback = false;
  bool _isWindowsWebView = false;
  bool _isMobileWebView = false;

  static const String _geogebraOnlineUrl =
      'https://www.geogebra.org/graphing';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (Platform.isWindows) {
      await _initWindows();
    } else if (Platform.isAndroid || Platform.isIOS) {
      await _initMobile();
    } else {
      if (mounted) {
        setState(() {
          _isDesktopFallback = true;
          _isLoading = false;
        });
      }
    }
  }

  // ─── 本地服务器启动 ──────────────────────────────────────────

  Future<String?> _startLocalServer() async {
    try {
      return await _localServer.start();
    } catch (e) {
      return null;
    }
  }

  // ─── Windows WebView2 ───────────────────────────────────────

  Future<void> _initWindows() async {
    try {
      final String? version = await WebviewController.getWebViewVersion();
      if (version == null) {
        if (mounted) {
          setState(() {
            _isDesktopFallback = true;
            _isLoading = false;
          });
        }
        return;
      }

      // 初始化 WebView2 环境
      try {
        await WebviewController.initializeEnvironment();
      } catch (_) {}

      // 启动本地 HTTP 服务器
      final localUrl = await _startLocalServer();
      if (localUrl == null) {
        if (mounted) {
          setState(() {
            _isDesktopFallback = true;
            _isLoading = false;
          });
        }
        return;
      }

      _winController = WebviewController();
      await _winController!.initialize();

      // JS → Flutter 通信兼容层
      _winMessageSubscription =
          _winController!.webMessage.listen(_onWinMessage);

      // 在文档加载前注入兼容层
      await _winController!.addScriptToExecuteOnDocumentCreated('''
        window.FlutterChannel = {
          postMessage: function(msg) {
            window.chrome.webview.postMessage(msg);
          }
        };
      ''');

      await _winController!.loadUrl(localUrl);

      _winController!.loadingState.listen((LoadingState state) {
        if (state == LoadingState.navigationCompleted &&
            !_isReady &&
            mounted) {
          Future.delayed(const Duration(seconds: 30), () {
            if (!_isReady && mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = '加载超时，请检查本地文件或网络连接';
              });
            }
          });
        }
      });

      if (!mounted) return;
      setState(() {
        _isWindowsWebView = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDesktopFallback = true;
          _isLoading = false;
        });
      }
    }
  }

  void _onWinMessage(dynamic message) {
    final String msg = message.toString();
    _handleJsMessage(msg);
  }

  // ─── 移动端 (Android/iOS) ──────────────────────────────────

  Future<void> _initMobile() async {
    final localUrl = await _startLocalServer();

    _mobileController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel('FlutterChannel',
          onMessageReceived: _onJsMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (!_isReady && mounted) {
              Future.delayed(const Duration(seconds: 30), () {
                if (!_isReady && mounted) {
                  setState(() {
                    _isLoading = false;
                    _hasError = true;
                    _errorMessage = '加载超时，请检查本地文件或网络连接';
                  });
                }
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = '资源加载失败: ${error.description}';
              });
            }
          },
        ),
      );

    if (localUrl != null) {
      await _mobileController!.loadRequest(Uri.parse(localUrl));
    } else {
      // 回退：用内联 HTML 通过 CDN 加载
      await _mobileController!.loadHtmlString(_fallbackHtml,
          baseUrl: 'https://www.geogebra.org/apps/5.4.920.0/');
    }

    if (!mounted) return;
    setState(() {
      _isMobileWebView = true;
    });
  }

  // ─── 浏览器回退 ────────────────────────────────────────────

  Future<void> _openGeogebraOnline() async {
    final Uri uri = Uri.parse(_geogebraOnlineUrl);
    try {
      final bool canLaunch = await canLaunchUrl(uri);
      if (!mounted) return;
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        _showError('无法打开浏览器，请检查系统默认浏览器设置');
      }
    } catch (e) {
      if (mounted) {
        _showError('打开浏览器失败: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '重试',
          onPressed: _openGeogebraOnline,
        ),
      ),
    );
  }

  // ─── JS 通信 ─────────────────────────────────────────────────

  void _onJsMessage(JavaScriptMessage message) {
    _handleJsMessage(message.message);
  }

  void _handleJsMessage(String msg) {
    if (msg == 'ready') {
      if (mounted) {
        setState(() {
          _isReady = true;
          _isLoading = false;
        });
      }
      if (widget.initialExpression != null) {
        _setExpression(widget.initialExpression!);
      }
    } else if (msg.startsWith('error:')) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = msg.substring(6);
        });
      }
    }
  }

  String _escapeJsString(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  Future<void> _setExpression(String expression) async {
    final String escaped = _escapeJsString(expression);
    final String js = 'window.GeogebraBridge.setExpression("$escaped")';
    if (_winController != null) {
      await _winController!.executeScript(js);
    } else if (_mobileController != null) {
      await _mobileController!.runJavaScript(js);
    }
  }

  Future<void> _reset() async {
    const String js = 'window.GeogebraBridge.reset()';
    if (_winController != null) {
      await _winController!.executeScript(js);
    } else if (_mobileController != null) {
      await _mobileController!.runJavaScript(js);
    }
  }

  Future<void> _retry() async {
    setState(() {
      _hasError = false;
      _isLoading = true;
      _errorMessage = '';
      _isReady = false;
    });

    final localUrl = await _startLocalServer();
    if (localUrl != null) {
      if (_winController != null) {
        await _winController!.loadUrl(localUrl);
      } else if (_mobileController != null) {
        await _mobileController!.loadRequest(Uri.parse(localUrl));
      }
    }
  }

  // ─── UI ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoGebra 数学工具'),
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        actions: <Widget>[
          if (_isReady)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '重置',
              onPressed: _reset,
            ),
          if (_isWindowsWebView || _isMobileWebView || _isDesktopFallback)
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              tooltip: '在浏览器中打开',
              onPressed: _openGeogebraOnline,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isDesktopFallback) return _buildDesktopFallbackBody();
    if (_isWindowsWebView) return _buildWebViewBody(isWindows: true);
    if (_isMobileWebView) return _buildWebViewBody(isWindows: false);
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildWebViewBody({required bool isWindows}) {
    return Stack(
      children: <Widget>[
        if (isWindows && _winController != null)
          Webview(_winController!)
        else if (!isWindows && _mobileController != null)
          WebViewWidget(controller: _mobileController!),

        if (_isLoading)
          Container(
            color: Colors.white,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('GeoGebra 加载中...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),

        if (_hasError)
          Container(
            color: Colors.white,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('加载失败',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage.isNotEmpty
                          ? _errorMessage
                          : '请检查本地文件或网络连接后重试',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopFallbackBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.show_chart, size: 64, color: Color(0xFF3F51B5)),
            const SizedBox(height: 16),
            const Text(
              'GeoGebra 数学工具',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '桌面端暂不支持内嵌 WebView\n请通过浏览器打开 GeoGebra 在线版',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _openGeogebraOnline,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('在浏览器中打开 GeoGebra'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _winMessageSubscription?.cancel();
    _winController?.dispose();
    super.dispose();
  }

  /// fallback HTML（CDN 回退）
  String get _fallbackHtml {
    return '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>GeoGebra</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body { width: 100%; height: 100%; overflow: hidden; position: fixed; background: #ffffff; }
#ggb-element { width: 100%; height: 100%; position: absolute; top: 0; left: 0; }
#loading { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); text-align: center; color: #666; font-family: sans-serif; z-index: 10; }
.spinner { width: 40px; height: 40px; margin: 0 auto 12px; border: 4px solid #e0e0e0; border-top-color: #3F51B5; border-radius: 50%; animation: spin 0.8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
#error { display: none; position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); text-align: center; color: #d32f2f; font-family: sans-serif; z-index: 10; padding: 20px; }
#error button { margin-top: 12px; padding: 8px 24px; background: #3F51B5; color: #fff; border: none; border-radius: 6px; font-size: 14px; cursor: pointer; }
</style>
</head>
<body>
<div id="loading"><div class="spinner"></div><span>GeoGebra 加载中...</span></div>
<div id="error"><p>GeoGebra 加载失败</p><button onclick="location.reload()">重试</button></div>
<div id="ggb-element"></div>
<script src="https://cdn.geogebra.org/apps/deployggb.js"></script>
<script>
window.GeogebraBridge = {
    _ready: false, _applet: null,
    onReady: function() { this._ready = true; if (window.FlutterChannel) { window.FlutterChannel.postMessage('ready'); } },
    onError: function(msg) { if (window.FlutterChannel) { window.FlutterChannel.postMessage('error:' + msg); } },
    setExpression: function(expr) { if (this._applet) { try { this._applet.setExpressionValue(expr); return true; } catch(e) { return false; } } return false; },
    getPNG: function() { if (this._applet) { try { return this._applet.getPNGBase64(1.0, true, 72); } catch(e) { return null; } } return null; },
    reset: function() { if (this._applet) { try { this._applet.reset(); return true; } catch(e) { return false; } } return false; },
    setMode: function(mode) { if (this._applet) { try { this._applet.setMode(mode); return true; } catch(e) { return false; } } return false; }
};
var params = {"appName":"graphing","width":"100%","height":"100%","showToolBar":true,"showAlgebraInput":true,"showMenuBar":true,"allowStyleBar":true,"enableLabelDrags":true,"enableShiftDragZoom":true,"enableRightClick":true,"showToolBarHelp":true,"showResetIcon":true,"appletOnLoad":function(api){ var loadingEl=document.getElementById('loading'); if(loadingEl) loadingEl.style.display='none'; window.GeogebraBridge._applet=api; window.GeogebraBridge.onReady(); }};
var applet = new GGBApplet(params, true);
function initGeogebra() { try { applet.inject('ggb-element'); setTimeout(function() { if (!window.GeogebraBridge._ready) { var loadingEl=document.getElementById('loading'); if(loadingEl) loadingEl.style.display='none'; var errEl=document.getElementById('error'); if(errEl) errEl.style.display='block'; if (window.FlutterChannel) { window.FlutterChannel.postMessage('error:timeout'); } } }, 30000); } catch(e) { document.getElementById('loading').style.display='none'; document.getElementById('error').style.display='block'; if (window.FlutterChannel) { window.FlutterChannel.postMessage('error:' + e.message); } } }
if (document.readyState === 'loading') { document.addEventListener('DOMContentLoaded', initGeogebra); } else { initGeogebra(); }
</script>
</body>
</html>
''';
  }
}
