import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:path_provider/path_provider.dart';
import 'note_model.dart';
import 'services/handwriting_ocr_service.dart';

enum CanvasMode { write, eraser, pan }
enum PaperBackground { blank, lined, grid }

class HandwritingStroke {
  final Color color;
  final double width;
  final List<Offset> points;

  HandwritingStroke({required this.color, required this.width, required this.points});

  Map<String, dynamic> toJson() => {
        'color': color.toARGB32(),
        'width': width,
        'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      };

  static HandwritingStroke fromJson(Map<String, dynamic> json) {
    return HandwritingStroke(
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
      points: (json['points'] as List)
          .map((p) => Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()))
          .toList(),
    );
  }
}

class PaperPage {
  List<HandwritingStroke> strokes = [];
  List<Offset> currentPoints = [];
  String recognizedText = '';
  PaperBackground background = PaperBackground.blank;
  double bgSpacing = 30.0;

  Map<String, dynamic> toJson() => {
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'recognizedText': recognizedText,
        'background': background.index,
        'bgSpacing': bgSpacing,
      };

  static PaperPage fromJson(Map<String, dynamic> json) {
    PaperPage page = PaperPage();
    page.strokes = (json['strokes'] as List?)
            ?.map((s) => HandwritingStroke.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
    page.recognizedText = json['recognizedText'] as String? ?? '';
    page.background = PaperBackground.values[json['background'] as int? ?? 0];
    page.bgSpacing = (json['bgSpacing'] as num?)?.toDouble() ?? 30.0;
    return page;
  }
}

class NoteHandwritingEditorPage extends StatefulWidget {
  final Note? note;

  const NoteHandwritingEditorPage({super.key, this.note});

  @override
  State<NoteHandwritingEditorPage> createState() => _NoteHandwritingEditorPageState();
}

class _NoteHandwritingEditorPageState extends State<NoteHandwritingEditorPage>
    with TickerProviderStateMixin {
  final GlobalKey _canvasKey = GlobalKey();
  final HandwritingOcrService _ocrService = HandwritingOcrService();

  List<PaperPage> _pages = [PaperPage()];
  int _currentPageIndex = 0;

  PaperPage get _currentPage => _pages[_currentPageIndex];

  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isRecognizing = false;
  bool _showPreview = true;
  CanvasMode _canvasMode = CanvasMode.write;

  static const double _eraserWidth = 24.0;

  Color get _activeColor =>
      _canvasMode == CanvasMode.eraser ? Colors.white : _selectedColor;
  double get _activeWidth =>
      _canvasMode == CanvasMode.eraser ? _eraserWidth : _strokeWidth;

  // 缩放相关
  double _scale = 1.0;
  double _baseScale = 1.0;
  static const double _minScale = 0.5;
  static const double _maxScale = 3.0;

  static const Size _paperSize = Size(700.0, 900.0);
  Offset _paperOffset = Offset.zero;
  AnimationController? _springController;
  Animation<Offset>? _springAnimation;

  static const double _pageFlipThreshold = 0.3;
  double _dragAccumulatedX = 0;
  bool _isPageFlipping = false;
  bool _isDrawing = false;
  bool _isScaling = false;

  final List<Color> _colors = [
    Colors.black,
    Colors.redAccent,
    Colors.blueAccent,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _loadNoteContent();
  }

  @override
  void dispose() {
    _springController?.dispose();
    super.dispose();
  }

  void _loadNoteContent() {
    if (widget.note != null && widget.note!.content.isNotEmpty) {
      try {
        final data = jsonDecode(widget.note!.content);
        if (data is Map && data['pages'] != null) {
          setState(() {
            _pages = (data['pages'] as List)
                .map((p) => PaperPage.fromJson(p as Map<String, dynamic>))
                .toList();
            if (_pages.isEmpty) _pages = [PaperPage()];
          });
        }
      } catch (e) {
        debugPrint('加载笔记内容失败: $e');
      }
    }
  }

  void _addPage() {
    setState(() {
      _pages.add(PaperPage());
      _currentPageIndex = _pages.length - 1;
      _paperOffset = Offset.zero;
    });
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _pages.length) return;
    setState(() {
      _currentPageIndex = index;
      _paperOffset = Offset.zero;
    });
  }

  void _undo() {
    setState(() {
      if (_currentPage.strokes.isNotEmpty) _currentPage.strokes.removeLast();
    });
  }

  void _clear() {
    setState(() {
      _currentPage.strokes.clear();
      _currentPage.currentPoints.clear();
      _currentPage.recognizedText = '';
      _paperOffset = Offset.zero;
    });
  }

  void _toggleMode(CanvasMode mode) {
    setState(() => _canvasMode = mode);
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (_canvasMode == CanvasMode.pan) {
      _isScaling = details.pointerCount > 1;
      if (_isScaling) _baseScale = _scale;
      _dragAccumulatedX = 0;
      _isPageFlipping = false;
    } else {
      _isDrawing = true;
      RenderBox box = _canvasKey.currentContext!.findRenderObject() as RenderBox;
      setState(() {
        _currentPage.currentPoints = [box.globalToLocal(details.focalPoint)];
      });
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_canvasMode == CanvasMode.pan) {
      if (_isScaling || details.pointerCount > 1) {
        if (!_isScaling) {
          _isScaling = true;
          _baseScale = _scale;
        }
        setState(() {
          _scale = (_baseScale * details.scale).clamp(_minScale, _maxScale);
        });
        return;
      }

      final delta = details.focalPointDelta.dx;
      _dragAccumulatedX += delta;
      setState(() => _paperOffset += details.focalPointDelta);

      final screenWidth = MediaQuery.of(context).size.width;
      final threshold = screenWidth * _pageFlipThreshold;

      if (!_isPageFlipping) {
        if (_dragAccumulatedX > threshold && _currentPageIndex < _pages.length - 1) {
          _isPageFlipping = true;
          _goToPage(_currentPageIndex + 1);
        } else if (_dragAccumulatedX < -threshold && _currentPageIndex > 0) {
          _isPageFlipping = true;
          _goToPage(_currentPageIndex - 1);
        }
      }
      return;
    }

    if (!_isDrawing) return;
    RenderBox box = _canvasKey.currentContext!.findRenderObject() as RenderBox;
    setState(() {
      _currentPage.currentPoints.add(box.globalToLocal(details.focalPoint));
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_canvasMode == CanvasMode.pan) {
      if (_isScaling) { _isScaling = false; return; }
      if (_isPageFlipping) { _isPageFlipping = false; _dragAccumulatedX = 0; return; }
      _dragAccumulatedX = 0;
      _animateBack();
      return;
    }

    if (!_isDrawing) return;
    _isDrawing = false;
    setState(() {
      if (_currentPage.currentPoints.isNotEmpty) {
        _currentPage.strokes.add(HandwritingStroke(
          color: _activeColor,
          width: _activeWidth,
          points: List.from(_currentPage.currentPoints),
        ));
        _currentPage.currentPoints.clear();
      }
    });
  }

  void _animateBack() {
    final screenSize = MediaQuery.of(context).size;
    final canvasWidth = screenSize.width - 16;
    final canvasHeight = screenSize.height * 0.45;
    final maxOffsetX = canvasWidth - _paperSize.width;
    final maxOffsetY = canvasHeight - _paperSize.height;

    if (_paperOffset.dx >= maxOffsetX &&
        _paperOffset.dy >= maxOffsetY &&
        _paperOffset.dx <= 0 &&
        _paperOffset.dy <= 0) {
      return;
    }

    double targetX = _paperOffset.dx.clamp(maxOffsetX, 0.0);
    double targetY = _paperOffset.dy.clamp(maxOffsetY, 0.0);
    final targetOffset = Offset(targetX, targetY);
    if (_paperOffset == targetOffset) return;

    _springController?.dispose();
    _springController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _springAnimation = Tween<Offset>(
      begin: _paperOffset, end: targetOffset,
    ).animate(CurvedAnimation(parent: _springController!, curve: Curves.elasticOut));

    _springController!.addListener(() {
      setState(() => _paperOffset = _springAnimation!.value);
    });
    _springController!.forward();
  }

  Future<void> _recognizeHandwriting() async {
    if (_currentPage.strokes.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('当前页没有笔迹')));
      return;
    }

    setState(() => _isRecognizing = true);

    try {
      RenderRepaintBoundary boundary =
          _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null && mounted) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        final result = await _ocrService.recognize(pngBytes);
        if (mounted) {
          setState(() => _currentPage.recognizedText = result);
        }
      }
    } catch (e) {
      debugPrint("识别失败: $e");
      if (mounted) {
        setState(() => _currentPage.recognizedText = '识别出错: $e');
      }
    } finally {
      if (mounted) setState(() => _isRecognizing = false);
    }
  }

  String _getAllRecognizedText() {
    return _pages
        .where((p) => p.recognizedText.isNotEmpty)
        .map((p) => p.recognizedText)
        .join('\n\n');
  }

  void _showTitleEditDialog() {
    final titleController = TextEditingController(
      text: widget.note?.title ?? '手写笔记',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('笔记标题'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(hintText: '请输入笔记标题', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _doSave(titleController.text.trim());
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _doSave(String title) {
    if (title.isEmpty) {
      title = '手写笔记 ${DateTime.now().toString().substring(0, 16)}';
    }
    final saveData = {'pages': _pages.map((p) => p.toJson()).toList()};
    final note = Note(
      title: title,
      content: jsonEncode(saveData),
      createTime: widget.note?.createTime ?? DateTime.now(),
      updateTime: DateTime.now(),
      noteType: 'handwriting',
      imagePaths: widget.note?.imagePaths ?? [],
    );
    Navigator.pop(context, note);
  }

  Future<void> _exportText() async {
    final allText = _getAllRecognizedText();
    if (allText.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('没有识别内容可导出')));
      return;
    }
    try {
      final directory = await getTemporaryDirectory();
      final file = await File('${directory.path}/handwriting_note.txt').create();
      await file.writeAsString(allText);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('已导出到: ${file.path}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  ColorScheme get cs => Theme.of(context).colorScheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text("手写笔记 (${_currentPageIndex + 1}/${_pages.length})",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "识别",
            onPressed: _currentPage.strokes.isEmpty ? null : _recognizeHandwriting,
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: "导出文本",
            onPressed: _exportText,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: "保存",
            onPressed: _showTitleEditDialog,
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return Row(children: [
              Expanded(child: _buildCanvas()),
              const VerticalDivider(width: 1),
              Expanded(child: _buildPreview()),
            ]);
          }
          return Column(children: [
            Expanded(flex: 3, child: _buildCanvas()),
            Container(height: 2, color: cs.outlineVariant),
            Expanded(flex: 2, child: _buildPreview()),
          ]);
        },
      ),
      bottomNavigationBar: _buildToolbar(),
    );
  }

  Widget _buildCanvas() {
    return Container(
      color: cs.surfaceContainerLowest,
      margin: const EdgeInsets.all(8),
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: cs.surfaceContainerLowest)),
            // 页面指示器
            Positioned(
              bottom: 8, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54, borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPageIndex + 1} / ${_pages.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
            // 可缩放纸张
            Positioned(
              left: 8 + _paperOffset.dx, top: 8 + _paperOffset.dy,
              child: Transform.scale(
                scale: _scale, alignment: Alignment.topLeft,
                child: GestureDetector(
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  onScaleEnd: _onScaleEnd,
                  child: Container(
                    width: _paperSize.width, height: _paperSize.height,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10, offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: RepaintBoundary(
                      key: _canvasKey,
                      child: CustomPaint(
                        painter: _BackgroundPainter(
                          backgroundType: _currentPage.background,
                          spacing: _currentPage.bgSpacing,
                        ),
                        foregroundPainter: _StrokePainter(
                          strokes: _currentPage.strokes,
                          currentPoints: _currentPage.currentPoints,
                          currentColor: _activeColor,
                          currentWidth: _activeWidth,
                        ),
                        size: _paperSize,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      color: cs.surface,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('识别结果预览',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
              TextButton.icon(
                onPressed: () => setState(() => _showPreview = !_showPreview),
                icon: Icon(_showPreview ? Icons.visibility : Icons.visibility_off, size: 18),
                label: Text(_showPreview ? '预览' : '纯文本', style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 1),
          if (_isRecognizing)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_currentPage.recognizedText.isEmpty)
            Expanded(
              child: Center(
                child: Text('点击识别按钮获取结果', style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: _showPreview
                    ? _buildRecognizedContent(_currentPage.recognizedText)
                    : SelectableText(_currentPage.recognizedText,
                        style: TextStyle(fontSize: 14, color: cs.onSurface)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecognizedContent(String text) {
    List<Widget> widgets = [];
    for (String line in text.split('\n')) {
      line = line.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      bool isLatex = line.contains(r'\') ||
          line.contains('^') || line.contains('_') ||
          line.contains('{') || line.contains('}');
      if (isLatex) {
        try {
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Math.tex(line, textStyle: const TextStyle(fontSize: 16),
              onErrorFallback: (err) => Text(line,
                  style: const TextStyle(fontSize: 14, color: Colors.blue)),
            ),
          ));
        } catch (e) {
          widgets.add(Text(line, style: const TextStyle(fontSize: 14, color: Colors.blue)));
        }
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(line, style: const TextStyle(fontSize: 16)),
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            // 模式切换
            _buildModeBtn(Icons.edit, '写字', CanvasMode.write),
            const SizedBox(width: 4),
            _buildModeBtn(Icons.auto_fix_high, '橡皮', CanvasMode.eraser),
            const SizedBox(width: 4),
            _buildModeBtn(Icons.pan_tool, '拖动', CanvasMode.pan),
            _divider(),
            // 背景类型
            IconButton(
              icon: Icon(
                _currentPage.background == PaperBackground.blank ? Icons.check_box_outline_blank :
                _currentPage.background == PaperBackground.lined ? Icons.view_agenda :
                Icons.grid_on,
                size: 22,
              ),
              tooltip: "背景类型",
              onPressed: _cycleBackground,
            ),
            if (_currentPage.background != PaperBackground.blank)
              InkWell(
                onTap: () {
                  double next = _currentPage.bgSpacing >= 60 ? 20 : _currentPage.bgSpacing + 20;
                  setState(() => _currentPage.bgSpacing = next);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer, borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('间距${_currentPage.bgSpacing.toInt()}',
                      style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer)),
                ),
              ),
            _divider(),
            // 页管理
            IconButton(icon: const Icon(Icons.add_box_outlined, size: 22), tooltip: "添加纸张", onPressed: _addPage),
            _divider(),
            // 笔刷粗细（非橡皮模式）
            if (_canvasMode != CanvasMode.eraser) ...[
              _buildPenBtn(2.0, "细"),
              _buildPenBtn(4.0, "中"),
              _buildPenBtn(8.0, "粗"),
              _divider(),
            ],
            // 撤销清空
            IconButton(icon: const Icon(Icons.undo, size: 22), tooltip: "撤销", onPressed: _undo),
            IconButton(icon: const Icon(Icons.delete_outline, size: 22), tooltip: "清空", onPressed: _clear),
            _divider(),
            // 颜色（非橡皮模式）
            if (_canvasMode != CanvasMode.eraser)
              ..._colors.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _buildColorBtn(c),
                  )),
          ]),
        ),
      ),
    );
  }

  void _cycleBackground() {
    setState(() {
      final types = PaperBackground.values;
      int idx = types.indexOf(_currentPage.background);
      _currentPage.background = types[(idx + 1) % types.length];
    });
  }

  Widget _divider() => Container(
        width: 1, height: 32, color: cs.outlineVariant,
        margin: const EdgeInsets.symmetric(horizontal: 6),
      );

  Widget _buildModeBtn(IconData icon, String label, CanvasMode mode) {
    final isSelected = _canvasMode == mode;
    return InkWell(
      onTap: () => _toggleMode(mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? cs.primary : cs.outlineVariant, width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: isSelected ? cs.primary : cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            fontSize: 11, color: isSelected ? cs.primary : cs.onSurfaceVariant,
          )),
        ]),
      ),
    );
  }

  Widget _buildPenBtn(double width, String label) {
    final isSelected = _strokeWidth == width;
    return InkWell(
      onTap: () => setState(() => _strokeWidth = width),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? cs.primary : cs.onSurfaceVariant,
        )),
      ),
    );
  }

  Widget _buildColorBtn(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: color, shape: BoxShape.circle,
          border: Border.all(color: isSelected ? cs.onSurface : Colors.transparent, width: 2),
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)] : null,
        ),
      ),
    );
  }
}

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

class _StrokePainter extends CustomPainter {
  final List<HandwritingStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;

  _StrokePainter({
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
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => true;
}
