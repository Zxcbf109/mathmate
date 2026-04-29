import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class EnhancedCropPage extends StatefulWidget {
  final File imageFile;

  const EnhancedCropPage({super.key, required this.imageFile});

  @override
  State<EnhancedCropPage> createState() => _EnhancedCropPageState();
}

class _EnhancedCropPageState extends State<EnhancedCropPage> {
  // 裁剪框的垂直边界（百分比 0.0 - 1.0）
  double _topPercent = 0.3;
  double _bottomPercent = 0.7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('调整识别范围', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.blue),
            onPressed: _processCrop, // 执行裁剪逻辑
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onVerticalDragUpdate: (details) {
              // 简单的手势判定：滑动位置靠近顶部则移动顶部边界，反之亦然
              final relativeY =
                  details.localPosition.dy / constraints.maxHeight;
              setState(() {
                if ((relativeY - _topPercent).abs() <
                    (relativeY - _bottomPercent).abs()) {
                  _topPercent = relativeY.clamp(0.0, _bottomPercent - 0.1);
                } else {
                  _bottomPercent = relativeY.clamp(_topPercent + 0.1, 1.0);
                }
              });
            },
            child: Stack(
              children: [
                // 1. 展示拍摄的原图
                Center(
                  child: Image.file(widget.imageFile, fit: BoxFit.contain),
                ),
                // 2. 绘制矩形遮罩层
                Positioned.fill(
                  child: CustomPaint(
                    painter: CropOverlayPainter(
                      topPercent: _topPercent,
                      bottomPercent: _bottomPercent,
                    ),
                  ),
                ),
                // 3. 辅助手柄
                _buildHandle(constraints.maxHeight * _topPercent, true),
                _buildHandle(constraints.maxHeight * _bottomPercent, false),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle(double y, bool isTop) {
    return Positioned(
      top: y - 10,
      left: 0,
      right: 0,
      child: Container(
        height: 20,
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  // 利用 image 库进行像素级裁剪
  Future<void> _processCrop() async {
    final bytes = await widget.imageFile.readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) return;

    final int x = 0;
    final int y = (decodedImage.height * _topPercent).toInt();
    final int width = decodedImage.width;
    final int height = (decodedImage.height * (_bottomPercent - _topPercent))
        .toInt();

    final croppedImage = img.copyCrop(
      decodedImage,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    // 保存并返回
    final croppedFile = File(
      widget.imageFile.path.replaceAll('.jpg', '_cropped.jpg'),
    )..writeAsBytesSync(img.encodeJpg(croppedImage));

    if (mounted) Navigator.pop(context, croppedFile);
  }
}

// 矩形遮罩绘制器
class CropOverlayPainter extends CustomPainter {
  final double topPercent;
  final double bottomPercent;

  CropOverlayPainter({required this.topPercent, required this.bottomPercent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    final topY = size.height * topPercent;
    final bottomY = size.height * bottomPercent;

    // 绘制上方阴影
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, topY), paint);
    // 绘制下方阴影
    canvas.drawRect(Rect.fromLTRB(0, bottomY, size.width, size.height), paint);

    // 绘制中间的矩形高亮框
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(Rect.fromLTRB(0, topY, size.width, bottomY), borderPaint);
  }

  @override
  bool shouldRepaint(CropOverlayPainter oldDelegate) => true;
}
