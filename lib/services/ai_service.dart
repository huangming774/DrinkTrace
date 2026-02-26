import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yinji/models/drink_record.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  late Dio _dio;

  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
  }

  Future<String> getHealthAdvice(List<DrinkRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('openai_api_key');
      var apiUrl = prefs.getString('openai_api_url') ?? 
          'https://api.openai.com/v1/chat/completions';
      final model = prefs.getString('openai_model') ?? 'gpt-3.5-turbo';

      if (apiKey == null || apiKey.isEmpty) {
        return '请先在"我的-AI配置"中设置OpenAI API Key';
      }

      // 兼容 NVIDIA API 格式：如果 URL 不包含完整路径，自动补全
      if (apiUrl.contains('nvidia.com') && !apiUrl.contains('/v1/')) {
        if (!apiUrl.endsWith('/')) {
          apiUrl += '/';
        }
        apiUrl += 'v1/chat/completions';
      }

      // 构建饮品数据摘要
      String dataPrompt = _buildDataPrompt(records);

      final response = await _dio.post(
        apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
        data: {
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': '''你是一位专业的健康顾问，专注于饮品健康管理。
请基于用户的饮品记录数据，提供个性化的健康建议。

要求：
1. 语气温和友好，不要过于严厉
2. 提供具体的数值建议
3. 给出可执行的行动点
4. 关注水分摄入、咖啡因、糖分、酒精等方面
5. 回复简洁明了，控制在200字以内
6. 使用中文回复'''
            },
            {
              'role': 'user',
              'content': dataPrompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        return content.toString().trim();
      } else {
        return 'AI服务暂时不可用，请稍后再试';
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return '请求超时，请检查网络连接';
      } else if (e.response?.statusCode == 401) {
        return 'API Key无效，请检查配置';
      } else if (e.response?.statusCode == 429) {
        return 'API调用次数超限，请稍后再试';
      } else {
        return 'AI服务异常：${e.message}';
      }
    } catch (e) {
      return '发生错误：$e';
    }
  }

  String _buildDataPrompt(List<DrinkRecord> records) {
    if (records.isEmpty) {
      return '用户今天还没有任何饮品记录。请给出一般性的饮水健康建议。';
    }

    // 统计数据
    int teaCount = 0;
    int alcoholCount = 0;
    int milkTeaCount = 0;
    int otherCount = 0;
    int totalMl = records.length * 300; // 假设每杯300ml

    List<String> drinkDetails = [];

    for (var record in records) {
      final hour = record.timestamp.hour;
      final minute = record.timestamp.minute;
      final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      
      drinkDetails.add('$timeStr - ${record.name}(${record.category})');

      switch (record.category) {
        case '茶':
          teaCount++;
          break;
        case '酒':
          alcoholCount++;
          break;
        case '奶茶':
          milkTeaCount++;
          break;
        default:
          otherCount++;
      }
    }

    return '''今日饮品记录分析：

总计：${records.length}杯，约${totalMl}ml
- 茶饮：${teaCount}杯
- 奶茶：${milkTeaCount}杯
- 酒类：${alcoholCount}杯
- 其他：${otherCount}杯

详细记录：
${drinkDetails.join('\n')}

请基于以上数据，提供个性化的健康建议，包括：
1. 总体评估
2. 具体建议（如需要补充多少水分、注意事项等）
3. 今日行动建议''';
  }
}

