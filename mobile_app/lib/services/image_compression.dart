import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;

class ImageCompressionService {
  /**
   * Compresses an image file before upload.
   * Target size: < 1MB
   */
  static Future<File?> compressImage(File file) async {
    final dir = await path_provider.getTemporaryDirectory();
    final targetPath = p.join(dir.absolute.path, "${DateTime.now().millisecondsSinceEpoch}.jpg");

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70, // Balanced quality/size
      minWidth: 1024,
      minHeight: 1024,
    );

    if (result == null) return null;
    return File(result.path);
  }
}
