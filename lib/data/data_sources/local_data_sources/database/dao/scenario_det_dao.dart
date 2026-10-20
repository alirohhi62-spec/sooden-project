import 'package:bms/data/data_sources/local_data_sources/database/dao/base_dao.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario_det.dart';
import 'package:floor/floor.dart';

@dao
abstract class ScenarioDetDao extends BaseDao<ScenarioDet> {
  ScenarioDetDao() : super(ScenarioDet.tableName);

  Future<List<ScenarioDet>> getByScenarioId(int scenarioId, String placeCode) async {
    final query = await appDB.rawQuery('''
          SELECT 
              sd.id AS id,
              sd.scenarioId AS scenarioId,
              sd.deviceId AS deviceId,
              d.code AS deviceCode,
              d.name AS deviceName,
              d.headline AS headline,
              d.code AS code,
              sd.value AS value
          FROM scenario_det AS sd
          LEFT JOIN devices AS d ON d.id = sd.deviceId
          WHERE sd.scenarioId = $scenarioId AND d.place = '$placeCode'
          ORDER BY 
           CASE 
             WHEN d.headline = 'U' THEN 1
             WHEN d.headline = 'V' THEN 2
             ELSE 3
           END;
    ''');

    List<ScenarioDet> scenarioDet = [];
    for (var element in query) {
      scenarioDet.add(ScenarioDet(
        id: element['id'] as int,
        scenarioId: element['scenarioId'] as int,
        deviceId: element['deviceId'] as int,
        deviceName: getDeviceName(element),
        value: element['value'] as String,
        headline: element['headline'] as String,
        code: element['code'] as String,
      ));
    }

    return scenarioDet;
  }

  String? getDeviceName(Map<String, Object?> element) {
    return element['deviceName'] == null
          ? Device(code:  element['deviceCode'] as String?).getName()
          : element['deviceName'] as String;
  }

  Future<List<ScenarioDet>> getScenarioValuesOfAPlace(
      int scenarioId, String floor, String place) async {
    final query = await appDB.rawQuery('''
          SELECT 
            sd.*
          FROM scenarios AS s
          LEFT JOIN scenario_det AS sd ON sd.scenarioId = s.id
          LEFT JOIN devices AS d ON d.id = sd.deviceId
          WHERE s.id = $scenarioId AND d.floor = '$floor' AND d.place = '$place'
    ''');

    List<ScenarioDet> scenarioDet = [];
    for (var element in query) {
      scenarioDet.add(ScenarioDet(
        id: element['id'] as int,
        scenarioId: element['scenarioId'] as int,
        deviceId: element['deviceId'] as int,
        value: element['value'] as String,
      ));
    }

    return scenarioDet;
  }

  Future<List<ScenarioDet>> getScenarioDet(int scenarioId) async {
    final query = await appDB.rawQuery('''
   SELECT sd.id, sd.scenarioId, sd.deviceId, sd.value, de.headline, de.code
   FROM scenario_det AS sd
   LEFT JOIN devices as de
   ON sd.deviceId = de.id
   WHERE sd.scenarioId = $scenarioId
   ORDER BY 
   CASE 
     WHEN de.headline = 'U' THEN 1
     WHEN de.headline = 'V' THEN 2
     ELSE 3
    END;
    ''');

    List<ScenarioDet> scenarioDet = [];
    for (var element in query) {
      scenarioDet.add(ScenarioDet(
        id: element['id'] as int,
        scenarioId: element['scenarioId'] as int,
        deviceId: element['deviceId'] as int,
        value: element['value'] as String,
        headline: element['headline'] as String?,
        code: element['code'] as String,
      ));
    }

    return scenarioDet;
  }
}
