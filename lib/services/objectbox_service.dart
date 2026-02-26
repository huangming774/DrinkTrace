import 'package:yinji/models/drink_record.dart';
import 'package:yinji/models/diary_entry.dart';
import 'package:yinji/objectbox.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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

  // Diary methods
  List<DiaryEntry> getAllDiaries() {
    final diaries = _diaryBox.getAll();
    diaries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return diaries;
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

