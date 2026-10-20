import 'package:bms/data/data_sources/local_data_sources/database/app_database.dart';
import 'package:floor/floor.dart';
import 'package:get/get.dart';

abstract class BaseDao<T> {

  late String tableName;
  final appDB = Get.find<AppDatabase>().database;

  BaseDao(this.tableName);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<int> insert(T t);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertList(List<T> t);

  Future<void> clear() async{
    await appDB.rawQuery('DELETE FROM $tableName');
  }

  Future<int> count() async {
    var result = await appDB.rawQuery('SELECT COUNT(1) AS count FROM $tableName');
    return result.first['count'] as int;
  }

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> update(T t);

  Future<void> deleteByKeyValue(String columnName, dynamic columnValue) async{
    var temp = await appDB.rawQuery('DELETE FROM $tableName WHERE $columnName = $columnValue');
    temp = temp;
  }

  Future<void> deleteAllSameRowsByKeyValue(String columnName, dynamic columnValue) async {
    var temp = await appDB.rawDelete('DELETE FROM $tableName WHERE $columnName = $columnValue');
    temp = temp;
  }

}
