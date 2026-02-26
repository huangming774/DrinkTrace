import 'package:objectbox/objectbox.dart';

@Entity()
class DiaryEntry {
  @Id()
  int id = 0;

  String title;
  String content;
  String mood;
  
  @Property(type: PropertyType.date)
  DateTime timestamp;
  
  List<String> tags;

  DiaryEntry({
    required this.title,
    required this.content,
    required this.mood,
    required this.timestamp,
    this.tags = const [],
  });

  String get tagsString => tags.join(',');
  set tagsString(String value) => tags = value.split(',').where((t) => t.isNotEmpty).toList();
}

