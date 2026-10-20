import 'package:bms/data/data_sources/local_data_sources/database/dao/base_dao.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario.dart';
import 'package:floor/floor.dart';

import '../../../../../core/utils/globals.dart';

@dao
abstract class ScenarioDao extends BaseDao<Scenario> {
  ScenarioDao() : super(Scenario.tableName);

  @Query('select * from scenarios where locationId = :locationId')
  Future<List<Scenario>> getAllScenarios(int locationId);

  @Query('select * from scenarios as s '
      'where s.floor isNull and '
      's.place isNull and '
      's.locationId = :locationId ORDER BY id DESC; ')
  Future<List<Scenario>> getGeneralScenarios(int locationId);

  Future<List<Scenario>> getScenarioBothFloorAndPlace(
      {required int locationId, String? placeCode, String? floor}) async {
    _logger(' getScenarioBothFloorAndPlace', 'locationId: $locationId ');

    final strQuery = '''
      SELECT * 
      FROM scenarios as s
      WHERE (place IS NULL AND floor = '$floor') 
      OR (place = '$placeCode' AND floor = '$floor') 
      AND s.locationId = $locationId ;
      ORDER BY id DESC;  
       ''';

    _logger('getScenarios', strQuery);

    final query = await appDB.rawQuery(strQuery);
    List<Scenario> scenario = [];
    for (var element in query) {
      scenario.add(Scenario(
        id: element['id'] as int,
        locationId: element['locationId'] as int,
        floor: element['floor'] as String?,
        place: element['place'] as String?,
        name: element['name'] as String?,
      ));
    }

    return scenario;
  }

  Future<List<Scenario>> getScenarioFloorAndPlaceAndGeneral(
      {required int locationId, String? placeCode, String? floor}) async {
    _logger(' getScenarioFloorAndPlaceAndGeneral', 'locationId: $locationId ');

    final strQuery = '''
      SELECT * 
      FROM scenarios
      WHERE (place IS NULL AND floor = '$floor' AND locationId = $locationId) 
      OR (place = '$placeCode' AND floor = '$floor' AND locationId = $locationId) 
      OR (place IS NULL AND floor IS NULL AND locationId = $locationId)  
      ORDER BY id DESC;  
       ''';

    _logger('getScenarios', strQuery);

    final query = await appDB.rawQuery(strQuery);
    List<Scenario> scenario = [];
    for (var element in query) {
      scenario.add(Scenario(
        id: element['id'] as int,
        locationId: element['locationId'] as int,
        floor: element['floor'] as String?,
        place: element['place'] as String?,
        name: element['name'] as String?,
      ));
    }

    return scenario;
  }

  void _logger(String key, String value) {
    doLogGlobal('app_database. H:$hashCode', key, value);
  }
}
