import 'package:flutter/material.dart';
import 'package:mathmate/beautiful_result_page.dart';
import 'package:mathmate/services/scanner_service.dart';

void main() => runApp(const MathMateApp());

class MathMateApp extends StatelessWidget {
  const MathMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _scanAndOpenResult(BuildContext context) async {
    final ScannerService scannerService = ScannerService();
    final scannedFile = await scannerService.startScanning(context);

    if (scannedFile == null || !context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GradientEntryPage(
          child: BeautifulResultPage(image: scannedFile),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.blue.withValues(alpha: 0.1)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 结果显示区
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    '拍一下，难题秒解决',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                // 拍照按钮
                GestureDetector(
                  onTap: () => _scanAndOpenResult(context),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientEntryPage extends StatefulWidget {
  final Widget child;

  const _GradientEntryPage({required this.child});

  @override
  State<_GradientEntryPage> createState() => _GradientEntryPageState();
}

class _GradientEntryPageState extends State<_GradientEntryPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (BuildContext context, Widget? child) {
        final double overlayOpacity = 1 - _fadeAnimation.value;
        return Stack(
          children: [
            Opacity(opacity: _fadeAnimation.value, child: widget.child),
            IgnorePointer(
              child: Opacity(
                opacity: overlayOpacity,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0B2545), Color(0xFF134074)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
