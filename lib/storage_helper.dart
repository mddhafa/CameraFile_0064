import 'dart:io';
import 'package:path/path.dart' as path;

class StorageHelper {
  static Future<String> _getFolderPath() async {
    final dir = Directory('/storage/emulated/0/DCIM/FlutterNativeCamBloc');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  static Future<File> saveImage(File file, String prefix) async {
    final dirPath = await _getFolderPath();
    final fileName =
        '$prefix${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
    final savedPath = path.join(dirPath, fileName);
    return await file.copy(savedPath);
  }
}
