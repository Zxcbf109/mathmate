import 'dart:io';

import 'package:edge_detection/edge_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerService {
  Future<File?> startScanning(BuildContext context) async {
    try {
      if (kIsWeb) {
        debugPrint('ScannerService: edge detection is not supported on web.');
        return null;
      }
      if (!context.mounted) {
        return null;
      }

      final PermissionStatus status = await Permission.camera.status;
      PermissionStatus grantedStatus = status;

      if (!status.isGranted) {
        grantedStatus = await Permission.camera.request();
      }

      if (!grantedStatus.isGranted) {
        if (grantedStatus.isPermanentlyDenied) {
          debugPrint('ScannerService: camera permission permanently denied.');
        }
        debugPrint('ScannerService: camera permission denied.');
        return null;
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String filename =
          'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String outputPath = path.join(tempDir.path, filename);

      final bool isSuccess = await EdgeDetection.detectEdge(outputPath);

      if (!isSuccess) {
        debugPrint('ScannerService: user cancelled scanning.');
        return null;
      }

      final File scannedFile = File(outputPath);
      if (!await scannedFile.exists()) {
        debugPrint('ScannerService: scanned file not found at $outputPath');
        return null;
      }

      return scannedFile;
    } catch (e, stackTrace) {
      debugPrint('ScannerService startScanning error: $e');
      debugPrint('$stackTrace');
      return null;
    }
  }
}
