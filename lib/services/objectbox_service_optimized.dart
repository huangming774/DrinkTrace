import 'package:yinji/models/drink_record.dart';
import 'package:yinji/models/diary_entry.dart';
import 'package:yinji/objectbox.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:isolate';

class ObjectBoxService {
  late final Store _store;
  late final Box<DrinkRecord> _drinkBox;
  late final Box<DiaryEntry> _diaryBox;

  static ObjectBoxService? _instance;

  ObjectBoxService._create(this._store) {
    _drinkBox = Box<DrinkRecord>(_store);
    _diaryBox = Box<DiaryEntry>(_store);
  }

  static Future<ObjectBoxService> create() async {
    if (_instance != null) return _instance!;

    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(
      directory: p.join(docsDir.path, 'objectbox'),
    );
    
    _instance = ObjectBoxService._create(store);
    return _instance!;
  }

  Box<DrinkRecord> get drinkBox => _drinkBox;

  /// 获取所有记录（优化：使用 Isolate 处理大量数据）
  Future<List<DrinkRecord>> getAllRecordsAsync() async {
    final records = _drinkBox.getAll();
    
    // 如果记录数量较少，直接返回
    if (records.length < 100) {
      return records;
    }
    
    // 大量数据时，在 Isolate 中处理排序等操作
    return await Isolate.run(() {
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    });
  }

  /// 同步获取所有记录（保留兼容性）
  List<DrinkRecord> getAllRecords() {
    return _drinkBox.getAll();
  }

  List<DrinkRecord> getTodayRecords() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _drinkBox
        .query(DrinkRecord_.timestamp
            .greaterOrEqual(startOfDay.millisecondsSinceEpoch)
            .and(DrinkRecord_.timestamp.lessThan(endOfDay.millisecondsSinceEpoch)))
        .build();

    final results = query.find();
    query.close();
    return results;
  }

  int addRecord(DrinkRecord record) {
    return _drinkBox.put(record);
  }

  void deleteRecord(int id) {
    _drinkBox.remove(id);
  }

  void updateRecord(DrinkRecord record) {
    _drinkBox.put(record);
  }

  /// 批量添加记录（优化：使用事务）
  Future<void> addRecordsBatch(List<DrinkRecord> records) async {
    await Isolate.run(() {
      _drinkBox.putMany(records);
    });
  }

  /// 批量删除记录（优化：使用事务）
  Future<void> deleteRecordsBatch(List<int> ids) async {
    await Isolate.run(() {
      _drinkBox.removeMany(ids);
    });
  }

  // Diary methods
  List<DiaryEntry> getAllDiaries() {
    final diaries = _diaryBox.getAll();
    diaries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return diaries;
  }

  /// 异步获取所有日记（优化版本）
  Future<List<DiaryEntry>> getAllDiariesAsync() async {
    final diaries = _diaryBox.getAll();
    
    if (diaries.length < 50) {
      diaries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return diaries;
    }
    
    return await Isolate.run(() {
      diaries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return diaries;
    });
  }

  int addDiary(DiaryEntry diary) {
    return _diaryBox.put(diary);
  }

  void deleteDiary(int id) {
    _diaryBox.remove(id);
  }

  void updateDiary(DiaryEntry diary) {
    _diaryBox.put(diary);
  }

  void close() {
    _store.close();
  }
}

