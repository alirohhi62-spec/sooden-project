
import 'package:bms/data/data_sources/local_data_sources/database/dao/base_dao.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:floor/floor.dart';

import '../../../../enums/place_code.dart';

@dao
abstract class PlaceDao extends BaseDao<Place> {
  PlaceDao() : super(Place.tableName);

  
  Future<List<Place>> getPlaces({required int locationId, String? floor}) async {
    final query = await appDB.rawQuery('''
          SELECT *
          FROM places AS p
          WHERE p.locationId = $locationId AND p.code != "${PlaceCode.ehzarAsansor.value}"
          ${floor != null ? "AND p.floor = '$floor'" : ""}
    ''');

    List<Place> places = [];
    for (var element in query) {
      places.add(Place(
        id: element['id'] as int,
        locationId: element['locationId'] as int,
        floor: element['floor'] as String,
        code: element['code'] as String,
        name: element['name'] as String?,
      ));
    }

    return places;
  }

  Future<bool> hasElevator({required int locationId, required String floor,}) async {
    final query = await appDB.rawQuery('''
          SELECT COUNT(1) AS count
          FROM places AS p
          WHERE p.locationId = $locationId AND p.floor = '$floor' AND p.code = "${PlaceCode.ehzarAsansor.value}"
    ''');

    return query.first['count'] as int > 0;
  }
}
