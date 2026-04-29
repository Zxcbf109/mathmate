import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// 🌟 1. 我们自己定义“每一笔”的数据结构
class DrawingStroke {
  final Color color;
  final double width;
  final List<Offset> points;

  DrawingStroke({required this.color, required this.width, required this.points});
}

class HandwritingPage extends StatefulWidget {
  const HandwritingPage({super.key});

  @override
  State<HandwritingPage> createState() => _HandwritingPageState();
}

class _HandwritingPageState extends State<HandwritingPage> {
  // 用于截图导出的 Key
  final GlobalKey _canvasKey = GlobalKey();

  // 核心数据：保存所有已经画完的线条
  final List<DrawingStroke> _strokes = [];
  // 核心数据：保存当前正在画的线条
  List<Offset> _currentPoints = [];

  // 当前画笔状态
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;

  // 预设颜色盘
  final List<Color> _colors = [
    Colors.black,
    Colors.redAccent,
    Colors.blueAccent,
    Colors.green,
    Colors.orange,
  ];

  // 撤销功能
  void _undo() {
    setState(() {
      if (_strokes.isNotEmpty) {
        _strokes.removeLast();
      }
    });
  }

  // 清空功能
  void _clear() {
    setState(() {
      _strokes.clear();
      _currentPoints.clear();
    });
  }

  // 🌟 核心：原生高清截图，带透明背景
  Future<void> _saveHandwriting() async {
    if (_strokes.isEmpty && _currentPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('画板是空的哦，随便画两笔吧')));
      return;
    }

    try {
      // 找到画布的边界
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // 导出为原生图片 (pixelRatio: 3.0 保证高清)
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        if (mounted) {
          Navigator.pop(context, pngBytes); // 完美打包发回上一页
        }
      }
    } catch (e) {
      debugPrint("导出图片失败: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("手写笔记", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.undo), tooltip: "撤销", onPressed: _undo),
          IconButton(icon: const Icon(Icons.delete_outline), tooltip: "清空", onPressed: _clear),
          TextButton(
            onPressed: _saveHandwriting,
            child: const Text("完成", style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 上方真实的画布区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.white, // 画板白色底色
                  // 🌟 2. 用 RepaintBoundary 包裹，用于导出透明图片
                  child: RepaintBoundary(
                    key: _canvasKey,
                    child: Container(
                      color: Colors.transparent, // 确保导出的图是透明背景
                      width: double.infinity,
                      height: double.infinity,
                      // 🌟 3. 监听手指滑动
                      child: GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            RenderBox box = _canvasKey.currentContext!.findRenderObject() as RenderBox;
                            _currentPoints = [box.globalToLocal(details.globalPosition)];
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            RenderBox box = _canvasKey.currentContext!.findRenderObject() as RenderBox;
                            _currentPoints.add(box.globalToLocal(details.globalPosition));
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            if (_currentPoints.isNotEmpty) {
                              // 一笔画完，把这笔独立的颜色和粗细存起来！
                              _strokes.add(DrawingStroke(
                                color: _selectedColor,
                                width: _strokeWidth,
                                points: List.from(_currentPoints),
                              ));
                              _currentPoints.clear();
                            }
                          });
                        },
                        // 🌟 4. 将线条交给我们的 CustomPainter 绘制
                        child: CustomPaint(
                          painter: _DrawingPainter(
                            strokes: _strokes,
                            currentPoints: _currentPoints,
                            currentColor: _selectedColor,
                            currentWidth: _strokeWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 2. 底部超酷工具栏
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPenStyleButton(icon: Icons.edit, size: 18, width: 2.0, label: "细笔"),
                      _buildPenStyleButton(icon: Icons.edit, size: 24, width: 4.0, label: "常规"),
                      _buildPenStyleButton(icon: Icons.brush, size: 30, width: 8.0, label: "记号笔"),
                    ],
                  ),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _colors.map((color) => _buildColorButton(color)).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.grey.shade400 : Colors.transparent, width: 3),
          boxShadow: [if (isSelected) const BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
        ),
      ),
    );
  }

  Widget _buildPenStyleButton({required IconData icon, required double size, required double width, required String label}) {
    final isSelected = _strokeWidth == width;
    return InkWell(
      onTap: () => setState(() => _strokeWidth = width),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: size, color: isSelected ? Colors.blue : Colors.grey[700]),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.blue : Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}

// 🌟 5. 我们自己手搓的渲染引擎，比第三方插件强百倍！
class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;

  _DrawingPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 绘制历史记录（每一笔都有自己的颜色和粗细）
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      _drawPath(canvas, stroke.points, paint);
    }

    // 2. 绘制当前正在画的线条
    if (currentPoints.isNotEmpty) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      _drawPath(canvas, currentPoints, paint);
    }
  }

  void _drawPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      canvas.drawPoints(ui.PointMode.points, points, paint);
      return;
    }
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}