import 'package:dart_mappable/dart_mappable.dart';
import 'package:objectbox/objectbox.dart';

part 'drink_record.mapper.dart';

@MappableClass()
@Entity()
class DrinkRecord with DrinkRecordMappable {
  @Id()
  int id;

  String name;
  String category; // 茶、酒、奶茶
  String emoji;
  double price;
  int rating; // 1-5
  String mood; // 疲惫、工作等
  String? comment;
  String? imagePath; // 图片路径
  double volume; // 容量 ml
  double alcoholDegree; // 酒精度数
  
  @Property(type: PropertyType.date)
  DateTime timestamp;

  DrinkRecord({
    this.id = 0,
    required this.name,
    required this.category,
    required this.emoji,
    required this.price,
    required this.rating,
    required this.mood,
    this.comment,
    this.imagePath,
    this.volume = 500,
    this.alcoholDegree = 0,
    required this.timestamp,
  });
}

