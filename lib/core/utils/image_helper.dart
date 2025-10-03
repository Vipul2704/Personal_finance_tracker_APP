// lib/core/utils/image_helper.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Get the app's images directory
  static Future<Directory> _getImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(appDir.path, 'transaction_images'));

    // Create directory if it doesn't exist
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir;
  }

  /// Generate unique filename for image
  static String _generateImageFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'transaction_${timestamp}_$random.jpg';
  }

  /// Check and request camera permission
  static Future<bool> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  /// Check and request storage permission (for gallery access)
  static Future<bool> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  /// Pick image from camera
  static Future<String?> pickImageFromCamera() async {
    try {
      // Request camera permission
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        throw Exception('Camera permission denied');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveImageToAppDirectory(image.path);
      }
    } catch (e) {
      print('Error picking image from camera: $e');
      rethrow;
    }
    return null;
  }

  /// Pick image from gallery
  static Future<String?> pickImageFromGallery() async {
    try {
      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveImageToAppDirectory(image.path);
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
      rethrow;
    }
    return null;
  }

  /// Save image to app's internal directory
  static Future<String> _saveImageToAppDirectory(String imagePath) async {
    final imagesDir = await _getImagesDirectory();
    final fileName = _generateImageFileName();
    final newPath = path.join(imagesDir.path, fileName);

    final originalFile = File(imagePath);
    final newFile = await originalFile.copy(newPath);

    print('Image saved to: ${newFile.path}');
    return newFile.path;
  }

  /// Show image picker options dialog
  static Future<String?> showImagePickerDialog({
    required Function() onCameraTap,
    required Function() onGalleryTap,
    required Function() onCancel,
  }) async {
    // This method returns the dialog widget configuration
    // The actual dialog will be shown in the UI layer
    return null;
  }

  /// Delete image file
  static Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        print('Image deleted: $imagePath');
        return true;
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
    return false;
  }

  /// Check if image file exists
  static Future<bool> imageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get image file size in bytes
  static Future<int> getImageSize(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      print('Error getting image size: $e');
    }
    return 0;
  }

  /// Clean up old images (optional maintenance function)
  static Future<void> cleanupOldImages({int daysOld = 30}) async {
    try {
      final imagesDir = await _getImagesDirectory();
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      await for (final entity in imagesDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            print('Cleaned up old image: ${entity.path}');
          }
        }
      }
    } catch (e) {
      print('Error during image cleanup: $e');
    }
  }

  /// Get all transaction images directory path
  static Future<String> getImagesDirectoryPath() async {
    final dir = await _getImagesDirectory();
    return dir.path;
  }
}