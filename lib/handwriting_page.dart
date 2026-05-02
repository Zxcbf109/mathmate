import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum DrawTool { pen, eraser }
enum PaperBackground { blank, lined, grid }

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
  final GlobalKey _canvasKey = GlobalKey();

  final List<DrawingStroke> _strokes = [];
  List<Offset> _currentPoints = [];

  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  DrawTool _currentTool = DrawTool.pen;
  PaperBackground _backgroundType = PaperBackground.blank;
  double _gridSpacing = 30.0;

  final List<Color> _colors = [
    Colors.black,
    Colors.redAccent,
    Colors.blueAccent,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
  ];

  // 橡皮擦：用白色画粗线
  static const Color _eraserColor = Colors.white;
  static const double _eraserWidth = 20.0;

  Color get _activeColor => _currentTool == DrawTool.eraser ? _eraserColor : _selectedColor;
  double get _activeWidth => _currentTool == DrawTool.eraser ? _eraserWidth : _strokeWidth;

  void _undo() {
    setState(() {
      if (_strokes.isNotEmpty) _strokes.removeLast();
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentPoints.clear();
    });
  }

  Future<void> _saveHandwriting() async {
    if (_strokes.isEmpty && _currentPoints.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('画板是空的哦，随便画两笔吧')));
      return;
    }

    try {
      RenderRepaintBoundary boundary =
          _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null && mounted) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        Navigator.pop(context, pngBytes);
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
            child: const Text("完成",
                style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 画布区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RepaintBoundary(
                  key: _canvasKey,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: CustomPaint(
                      painter: _BackgroundPainter(
                        backgroundType: _backgroundType,
                        spacing: _gridSpacing,
                      ),
                      foregroundPainter: _DrawingPainter(
                        strokes: _strokes,
                        currentPoints: _currentPoints,
                        currentColor: _activeColor,
                        currentWidth: _activeWidth,
                      ),
                      child: GestureDetector(
                        onPanStart: (details) {
                          RenderBox box = _canvasKey.currentContext!
                              .findRenderObject() as RenderBox;
                          setState(() {
                            _currentPoints = [box.globalToLocal(details.globalPosition)];
                          });
                        },
                        onPanUpdate: (details) {
                          RenderBox box = _canvasKey.currentContext!
                              .findRenderObject() as RenderBox;
                          setState(() {
                            _currentPoints.add(box.globalToLocal(details.globalPosition));
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            if (_currentPoints.isNotEmpty) {
                              _strokes.add(DrawingStroke(
                                color: _activeColor,
                                width: _activeWidth,
                                points: List.from(_currentPoints),
                              ));
                              _currentPoints.clear();
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 底部工具栏
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 工具切换：画笔 / 橡皮擦
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildToolButton(DrawTool.pen, Icons.edit, "画笔"),
                      const SizedBox(width: 16),
                      _buildToolButton(DrawTool.eraser, Icons.auto_fix_high, "橡皮擦"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 背景类型
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBgButton(PaperBackground.blank, "空白"),
                      const SizedBox(width: 8),
                      _buildBgButton(PaperBackground.lined, "横线"),
                      const SizedBox(width: 8),
                      _buildBgButton(PaperBackground.grid, "网格"),
                    ],
                  ),
                  if (_backgroundType != PaperBackground.blank) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("间距:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Slider(
                          value: _gridSpacing,
                          min: 20,
                          max: 80,
                          divisions: 6,
                          onChanged: (v) => setState(() => _gridSpacing = v),
                        ),
                        Text("${_gridSpacing.toInt()}px",
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                  const Divider(height: 28),
                  // 笔刷粗细
                  if (_currentTool == DrawTool.pen) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPenButton(Icons.edit, 18, 2.0, "细笔"),
                        _buildPenButton(Icons.edit, 24, 4.0, "常规"),
                        _buildPenButton(Icons.brush, 30, 8.0, "记号笔"),
                      ],
                    ),
                    const Divider(height: 28),
                  ],
                  // 颜色选择（仅画笔模式）
                  if (_currentTool == DrawTool.pen)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _colors.map((c) => _buildColorButton(c)).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(DrawTool tool, IconData icon, String label) {
    final isSelected = _currentTool == tool;
    return InkWell(
      onTap: () => setState(() => _currentTool = tool),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.12) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.blue : Colors.grey[700]),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.grey[700],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBgButton(PaperBackground bg, String label) {
    final isSelected = _backgroundType == bg;
    return InkWell(
      onTap: () => setState(() => _backgroundType = bg),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, color: isSelected ? Colors.blue : Colors.grey[600],
        )),
      ),
    );
  }

  Widget _buildPenButton(IconData icon, double size, double width, String label) {
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
            Text(label, style: TextStyle(
              fontSize: 12, color: isSelected ? Colors.blue : Colors.grey[700],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.grey.shade500 : Colors.transparent, width: 3,
          ),
          boxShadow: [
            if (isSelected) const BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
      ),
    );
  }
}

// 背景绘制器：横线 / 网格
class _BackgroundPainter extends CustomPainter {
  final PaperBackground backgroundType;
  final double spacing;

  _BackgroundPainter({required this.backgroundType, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundType == PaperBackground.blank) return;

    final paint = Paint()
      ..color = const Color(0xFFD0E0F0)
      ..strokeWidth = 0.5;

    if (backgroundType == PaperBackground.lined) {
      double y = spacing;
      while (y < size.height) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        y += spacing;
      }
    } else if (backgroundType == PaperBackground.grid) {
      double y = spacing;
      while (y < size.height) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        y += spacing;
      }
      double x = spacing;
      while (x < size.width) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        x += spacing;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) =>
      backgroundType != oldDelegate.backgroundType || spacing != oldDelegate.spacing;
}

// 笔画绘制器
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
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      _drawPath(canvas, stroke.points, paint);
    }

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
