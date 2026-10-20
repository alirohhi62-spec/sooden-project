import 'package:floor/floor.dart';

@Entity(tableName: Logger.tableName)
class Logger {
  @PrimaryKey(autoGenerate: true)
  int? id;


  String? time;
  String? className;
  String? methodName;
  String? value;


  Logger({
    this.id,
    this.time,
    this.className,
    this.methodName,
    this.value,
  });

  static const tableName = 'logger';
}
