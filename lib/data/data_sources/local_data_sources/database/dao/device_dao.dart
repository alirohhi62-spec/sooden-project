import 'package:bms/core/utils/communication_constants.dart';
import 'package:bms/data/data_sources/local_data_sources/database/dao/base_dao.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:floor/floor.dart';

import '../../../../enums/headline_code.dart';
import '../../../../model/headline.dart';

@dao
abstract class DeviceDao extends BaseDao<Device> {
  DeviceDao() : super(Device.tableName);

  Future<List<String>> getFloors(int locationId) async {
    final query = await appDB.rawQuery('''
          SELECT
            d.floor
          FROM devices AS d
          WHERE d.locationId = $locationId AND floor IS NOT NULL
          GROUP BY d.floor
    ''');

    List<String> floors = [];

    for (var element in query) {
      floors.add(element['floor'] as String);
    }

    return floors;
  }

  Future<List<Headline>> getHeadLines(int locationId,String floor, String place) async {
    final query = await appDB.rawQuery('''
          SELECT 
            d.headline AS headline,
            COUNT(1) AS count
          FROM devices AS d
          WHERE d.floor = '$floor' 
          AND d.place = '$place' 
          AND d.locationId = $locationId 
          AND NOT (d.headline = 'U' AND d.code = '${SocketConstants.hiddenDevice}')
          AND NOT (d.headline = 'V' AND d.code = '${SocketConstants.hiddenDevice}')
          GROUP BY d.headline
    ''');

    List<Headline> headlines = [];

    headlines.add(Headline(code: HeadlineCode.get('U'), countOfDevices: 0, active: false));
    headlines.add(Headline(code: HeadlineCode.get('V'), countOfDevices: 0, active: false));
    headlines.add(Headline(code: HeadlineCode.get('W'), countOfDevices: 0, active: false));
    headlines.add(Headline(code: HeadlineCode.get('X'), countOfDevices: 0, active: true));

    for (var queryElement in query) {
      for (var headlineElement in headlines) {
        if (queryElement['headline'] == headlineElement.code.value) {
          headlineElement.countOfDevices = queryElement['count'] as int?;
          headlineElement.active = true;
        }
      }
    }

    return headlines;
  }

  Future<List<Device>> getDevicesByLocation({required int locationId}) async {
    final query = await appDB.rawQuery('''
          SELECT *
          FROM devices AS d
          WHERE d.locationId = $locationId 
          AND floor IS NOT NULL
    ''');

    List<Device> devices = [];
    for (var element in query) {
      devices.add(Device(
        id: element['id'] as int,
        locationId: element['locationId'] as int,
        floor: element['floor'] as String,
        place: element['place'] as String,
        headline: element['headline'] as String,
        code: element['code'] as String,
        name: element['name'] as String?,
        value: element['value'] as String?,
      ));
    }

    return devices;
  }

  Future<List<Device>> getDevices(
      {required int locationId, required String floor, required String place, required String headline}) async {
    final query = await appDB.rawQuery('''
          SELECT *
          FROM devices AS d
          WHERE d.floor = '$floor' 
          AND d.place = '$place' 
          AND d.headline = '$headline' 
          AND d.locationId = $locationId 
          AND floor IS NOT NULL
    ''');

    List<Device> devices = [];
    for (var element in query) {
      devices.add(Device(
        id: element['id'] as int,
        locationId: element['locationId'] as int,
        floor: element['floor'] as String,
        place: element['place'] as String,
        headline: element['headline'] as String,
        code: element['code'] as String,
        name: element['name'] as String?,
        value: element['value'] as String?,
      ));
    }

    return devices;
  }

  Future<List<Device>> getDevicesMuteHidden(
      {required int locationId, required String floor, required String place, required String headline}) async {
    final query = await appDB.rawQuery('''
          SELECT *
          FROM devices AS d
          WHERE d.floor = '$floor' 
          AND d.place = '$place' 
          AND d.headline = '$headline' 
          AND d.locationId = $locationId 
          AND NOT d.code = '${SocketConstants.hiddenDevice}'
          AND floor IS NOT NULL
    ''');

    List<Device> devices = [];
    for (var element in query) {
      devices.add(Device(
        id: element['id'] as int,
        locationId: element['locationId'] as int,
        floor: element['floor'] as String,
        place: element['place'] as String,
        headline: element['headline'] as String,
        code: element['code'] as String,
        name: element['name'] as String?,
        value: element['value'] as String?,
        secondValue: element['secondValue'] as String?,
      ));
    }

    return devices;
  }

  Future<List<Device>> getDevicesOfFloor({required int locationId,required String floor, required String headline}) async {
    final query = await appDB.rawQuery('''
          SELECT *
          FROM devices AS d
          WHERE d.floor = '$floor' 
          AND d.headline = '$headline' 
          AND d.locationId = $locationId 
          AND floor IS NOT NULL
    ''');

    List<Device> devices = [];
    for (var element in query) {
      devices.add(Device(
        id: element['id'] as int,
        locationId: element['locationId'] as int,
        floor: element['floor'] as String,
        place: element['place'] as String,
        headline: element['headline'] as String,
        code: element['code'] as String,
        name: element['name'] as String?,
        value: element['value'] as String?,
      ));
    }

    return devices;
  }

  Future<List<Device>> getBurglarAlarmDevices(int locationId) async {
    final query = await appDB.rawQuery('''
          SELECT *
          FROM devices AS d
          WHERE d.locationId = $locationId 
          AND floor isNull and place isNull
    ''');

    List<Device> devices = [];
    for (var element in query) {
      devices.add(Device(
        id: element['id'] as int,
        locationId: element['locationId'] as int,
        headline: element['headline'] as String,
        code: element['code'] as String,
        name: element['name'] as String?,
        value: element['value'] as String?,
      ));
    }

    return devices;
  }

  Future<int> updateBurglarAlarmDevices(
      int locationId, String headline, String code, String value) async {
    var updateQuery = '''
    UPDATE devices
    SET value = '$value'
    WHERE locationId = $locationId AND code = '$code' AND headline = '$headline'
''';

    return await appDB.rawUpdate(updateQuery);
  }

  Future<int> updateCurtainDevices(Device device) async {
    var updateQuery = '''
    UPDATE devices
    SET value = '${device.value}', secondValue = '${device.secondValue}'
    WHERE locationId = ${device.locationId} 
    AND floor = '${device.floor}' 
    AND place = '${device.place}' 
    AND headline = '${device.headline}'
    And code = '${device.code}'
''';

    return await appDB.rawUpdate(updateQuery);
  }
}
