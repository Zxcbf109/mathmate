import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GeogebraPage extends StatefulWidget {
  const GeogebraPage({super.key});

  @override
  State<GeogebraPage> createState() => _GeogebraPageState();
}

class _GeogebraPageState extends State<GeogebraPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(_geogebraHtml);
  }

  String get _geogebraHtml {
    return '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GeoGebra</title>
    <style>
        body, html {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            overflow: hidden;
        }
        #ggb-element {
            width: 100%;
            height: 100%;
        }
    </style>
</head>
<body>
    <div id="ggb-element"></div>
    <script src="https://cdn.geogebra.org/apps/deployggb.js"></script>
    <script>
        var params = {
            "appName": "graphing",
            "width": "100%",
            "height": "100%",
            "showToolBar": true,
            "showAlgebraInput": true,
            "showMenuBar": true,
            "allowStyleBar": true,
            "enableLabelDrags": true,
            "enableShiftDragZoom": true,
            "enableRightClick": true,
            "capturingThreshold": 3,
            "showToolBarHelp": true,
            "errorDialogsActive": true,
            "useBrowserForJS": false
        };
        var applet = new GGBApplet(params, true);
        window.addEventListener("load", function() {
            applet.inject('ggb-element');
        });
    </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoGebra 数学工具'),
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}