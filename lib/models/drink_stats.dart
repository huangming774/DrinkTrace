import 'package:signals/signals.dart';

// 全局数据刷新信号
final dataRefreshSignal = signal(0);

class DrinkStats {
  final Signal<int> teaCount = signal(0);
  final Signal<int> alcoholCount = signal(0);
  final Signal<int> milkTeaCount = signal(0);

  void updateStats(List<dynamic> records) {
    int tea = 0;
    int alcohol = 0;
    int milkTea = 0;

    final today = DateTime.now();
    for (var record in records) {
      if (record.timestamp.year == today.year &&
          record.timestamp.month == today.month &&
          record.timestamp.day == today.day) {
        switch (record.category) {
          case '茶':
            tea++;
            break;
          case '酒':
            alcohol++;
            break;
          case '奶茶':
            milkTea++;
            break;
        }
      }
    }

    teaCount.value = tea;
    alcoholCount.value = alcohol;
    milkTeaCount.value = milkTea;
  }
}

