import 'package:bms/data/data_sources/local_data_sources/database/dao/base_dao.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/location.dart';
import 'package:floor/floor.dart';

@dao
abstract class LocationDao extends BaseDao<Location> {
  LocationDao() : super(Location.tableName);

  Future<bool> isExist({required String mac}) async {
    final query = await appDB.rawQuery('''
          SELECT COUNT(1) AS count
          FROM locations AS l
          WHERE l.mac = '$mac'
    ''');

    return query.first['count'] as int > 0;
  }

  @Query('UPDATE locations SET isSelected = CASE WHEN id = :id THEN 1 ELSE 0 END')
  Future<void> updateSelectedLocation(int id);

  @Query('SELECT * FROM locations AS l WHERE l.id = :id')
  Future<Location?> get(int id);

  @Query('SELECT * FROM locations')
  Future<List<Location>> all();

  @Query('SELECT * FROM locations WHERE isSelected = 1 LIMIT 1')
  Future<Location?> getSelectedLocation();

  @Query('SELECT * FROM locations ORDER BY id LIMIT 1')
  Future<Location?> getFirstLocation();

  Future<Location> getSelectedOrFirstLocation() async {
    final selectedLocation = await getSelectedLocation();
    if (selectedLocation != null) {
      return selectedLocation;
    } else {
      final firstLocation = await getFirstLocation();
      return firstLocation!;
    }
  }
}
