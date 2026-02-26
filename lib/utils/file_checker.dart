import 'dart:io';
import 'dart:isolate';

/// 文件检查工具类（使用 Isolate 批量检查）
class FileChecker {
  /// 批量检查文件是否存在（在 Isolate 中执行）
  static Future<Map<String, bool>> batchCheckExists(List<String> paths) async {
    if (paths.isEmpty) return {};
    
    return await Isolate.run(() {
      final results = <String, bool>{};
      for (var path in paths) {
        try {
          results[path] = File(path).existsSync();
        } catch (e) {
          results[path] = false;
        }
      }
      return results;
    });
  }
  
  /// 单个文件检查（快速路径）
  static Future<bool> checkExists(String path) async {
    try {
      return await File(path).exists();
    } catch (e) {
      return false;
    }
  }
}


