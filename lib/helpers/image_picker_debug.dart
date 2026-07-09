import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerDebugHelper {
  /// Check if image picker is available and permissions are granted
  static Future<Map<String, dynamic>> checkImagePickerStatus() async {
    final result = <String, dynamic>{};

    try {
      // Check platform
      result['platform'] = Platform.operatingSystem;
      result['isIOS'] = Platform.isIOS;
      result['isAndroid'] = Platform.isAndroid;

      // Check if we can access the image picker
      final picker = ImagePicker();
      result['imagePickerAvailable'] = true;

      // Try to check permissions (this will request permission if not granted)
      try {
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 100,
          maxHeight: 100,
        );
        result['permissionGranted'] = image != null;
        result['permissionMessage'] = image != null
            ? 'Permission granted and image picked successfully'
            : 'Permission granted but no image selected';
      } catch (e) {
        result['permissionGranted'] = false;
        result['permissionError'] = e.toString();
      }
    } catch (e) {
      result['imagePickerAvailable'] = false;
      result['error'] = e.toString();
    }

    return result;
  }

  static Future<void> printDebugInfo() async {
    if (kDebugMode) {
      final status = await checkImagePickerStatus();
      debugPrint('=== IMAGE PICKER DEBUG INFO ===');
      status.forEach((key, value) {
        debugPrint('$key: $value');
      });
      debugPrint('===============================');
    }
  }

  /// Check if an image file is valid
  static Future<Map<String, dynamic>> validateImageFile(String path) async {
    final result = <String, dynamic>{};

    try {
      final file = File(path);
      result['exists'] = await file.exists();

      if (result['exists']) {
        result['size'] = await file.length();
        result['sizeInMB'] = (result['size'] / (1024 * 1024)).toStringAsFixed(
          2,
        );

        // Check if it's a valid image by trying to read it
        try {
          final bytes = await file.readAsBytes();
          result['readable'] = true;
          result['bytesLength'] = bytes.length;
        } catch (e) {
          result['readable'] = false;
          result['readError'] = e.toString();
        }
      }
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }
}
