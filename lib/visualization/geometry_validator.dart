import 'package:mathmate/visualization/geometry_models.dart';
import 'package:mathmate/visualization/safe_json_parser.dart';

class GeometryValidationResult {
  final bool isValid;
  final String? error;
  final GeometryScene? scene;

  const GeometryValidationResult({
    required this.isValid,
    this.error,
    this.scene,
  });
}

class GeometryValidator {
  const GeometryValidator();

  GeometryValidationResult validate(Map<String, dynamic> json) {
    try {
      if (!json.containsKey('viewport') || !json.containsKey('elements')) {
        return const GeometryValidationResult(
          isValid: false,
          error: 'GeometryJSON must include viewport and elements.',
        );
      }

      final SafeJsonParser parser = const SafeJsonParser();
      final GeometryScene scene = GeometryScene.fromJson(json, parser: parser);
      if (scene.elements.isEmpty) {
        return GeometryValidationResult(isValid: true, scene: scene);
      }

      final bool hasBadElement = scene.elements.any(
        (GeometryElement element) =>
            element.id == 'unknown' || element.type == 'unknown',
      );
      if (hasBadElement) {
        return const GeometryValidationResult(
          isValid: false,
          error: 'GeometryJSON contains elements with missing id/type.',
        );
      }

      return GeometryValidationResult(isValid: true, scene: scene);
    } catch (e) {
      return GeometryValidationResult(
        isValid: false,
        error: 'Invalid GeometryJSON: $e',
      );
    }
  }
}
