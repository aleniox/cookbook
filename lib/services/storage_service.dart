import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../helpers/platform_helper.dart';

class StorageService {
  static Future<String> getAppDocumentsDirectory() async {
    if (PlatformHelper.isMobile) {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } else {
      // Desktop
      final directory = await getApplicationSupportDirectory();
      return directory.path;
    }
  }

  static Future<String> getRecipeImagesDirectory() async {
    final baseDir = await getAppDocumentsDirectory();
    final imagesDir = Directory('$baseDir/recipe_images');

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir.path;
  }

  static Future<String> saveRecipeImage(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist');
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${sourcePath.split('/').last}';
      final targetDir = await getRecipeImagesDirectory();
      final targetPath = '$targetDir/$fileName';

      await sourceFile.copy(targetPath);
      return targetPath;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  static Future<void> deleteRecipeImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  static Future<List<String>> getAllRecipeImages() async {
    try {
      final dir = Directory(await getRecipeImagesDirectory());
      if (!await dir.exists()) {
        return [];
      }

      final files = await dir.list().toList();
      return files.whereType<File>().map((f) => f.path).toList();
    } catch (e) {
      throw Exception('Failed to fetch images: $e');
    }
  }
}
