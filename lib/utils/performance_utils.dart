import 'dart:typed_data';
import 'dart:isolate';
import 'dart:convert';
import 'package:image/image.dart' as img;

/// 图片处理工具类（使用 Isolate 优化）
class ImageProcessor {
  /// 压缩图片（在 Isolate 中执行）
  static Future<Uint8List> compressImage({
    required String imagePath,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    return await Isolate.run(() => _compressImageSync(
      imagePath: imagePath,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality,
    ));
  }

  /// 同步压缩图片（在 Isolate 中调用）
  static Uint8List _compressImageSync({
    required String imagePath,
    required int maxWidth,
    required int maxHeight,
    required int quality,
  }) {
    // 读取图片
    final bytes = img.decodeImage(Uint8List.fromList([]));
    if (bytes == null) throw Exception('无法解码图片');

    // 计算缩放比例
    int width = bytes.width;
    int height = bytes.height;
    
    if (width > maxWidth || height > maxHeight) {
      final ratio = (maxWidth / width).clamp(0.0, maxHeight / height);
      width = (width * ratio).round();
      height = (height * ratio).round();
    }

    // 调整大小
    final resized = img.copyResize(bytes, width: width, height: height);

    // 编码为 JPEG
    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  }

  /// 批量压缩图片（并行处理）
  static Future<List<Uint8List>> compressImages({
    required List<String> imagePaths,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    return await Future.wait(
      imagePaths.map((path) => compressImage(
        imagePath: path,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      )),
    );
  }
}

/// JSON 处理工具类（使用 Isolate 优化）
class JsonProcessor {
  /// 编码 JSON（在 Isolate 中执行）
  static Future<String> encode(dynamic data) async {
    return await Isolate.run(() => jsonEncode(data));
  }

  /// 解码 JSON（在 Isolate 中执行）
  static Future<dynamic> decode(String jsonString) async {
    return await Isolate.run(() => jsonDecode(jsonString));
  }

  /// 批量编码（并行处理）
  static Future<List<String>> encodeList(List<dynamic> dataList) async {
    return await Future.wait(
      dataList.map((data) => encode(data)),
    );
  }

  /// 批量解码（并行处理）
  static Future<List<dynamic>> decodeList(List<String> jsonStrings) async {
    return await Future.wait(
      jsonStrings.map((json) => decode(json)),
    );
  }
}

/// 数据处理工具类（使用零拷贝优化）
class DataProcessor {
  /// 使用 TransferableTypedData 传输大数据
  static Future<Uint8List> processLargeData(Uint8List data) async {
    // 创建可传输的数据
    final transferable = TransferableTypedData.fromList([data]);

    return await Isolate.run(() {
      // 在 Isolate 中物化数据（零拷贝）
      final materialized = transferable.materialize().asUint8List();
      
      // 处理数据
      return _processBytes(materialized);
    });
  }

  static Uint8List _processBytes(Uint8List bytes) {
    // 实际的数据处理逻辑
    return bytes;
  }

  /// 批量处理大数据（并行 + 零拷贝）
  static Future<List<Uint8List>> processLargeDataList(
    List<Uint8List> dataList,
  ) async {
    return await Future.wait(
      dataList.map((data) => processLargeData(data)),
    );
  }
}

