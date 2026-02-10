import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class ImageStore {
  /// Save image bytes to disk and return the file path.
  /// Used to persist images for slides.
  static Future<String> saveImage(String id, Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/img_$id.png');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Load image bytes from disk using the ID.
  static Future<Uint8List?> loadImage(String id) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/img_$id.png');
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (_) {}
    return null;
  }

  /// Delete image from disk.
  static Future<void> deleteImage(String id) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/img_$id.png');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
