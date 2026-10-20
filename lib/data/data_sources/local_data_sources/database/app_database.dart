import 'dart:async';

import 'package:bms/core/utils/globals.dart';
import 'package:bms/data/data_sources/local_data_sources/database/dao/device_dao.dart';
import 'package:bms/data/data_sources/local_data_sources/database/dao/location_dao.dart';
import 'package:bms/data/data_sources/local_data_sources/database/dao/logger_dao.dart';
import 'package:bms/data/data_sources/local_data_sources/database/dao/place_dao.dart';
import 'package:bms/data/data_sources/local_data_sources/database/dao/scenario_dao.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/logger.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario_det.dart';
import 'package:floor/floor.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'dao/scenario_det_dao.dart';
import 'model/location.dart';

part 'app_database.g.dart';

@Database(version: 2, entities: [Location, Place, Device, Scenario, ScenarioDet,Logger])
abstract class AppDatabase extends FloorDatabase {
  static Future<AppDatabase> init() {
    return Get.putAsync<AppDatabase>(() async {
      final database = await $FloorAppDatabase.databaseBuilder('bms.db').build();
      return database;
    });
  }

  LocationDao get locationDao;

  PlaceDao get placeDao;

  DeviceDao get deviceDao;

  ScenarioDao get scenarioDao;

  ScenarioDetDao get scenarioDetDao;

  LoggerDao get loggerDao;

  clearWholeTable(){
    _logger('clearWholeTable','Clearing...');
    locationDao.clear();
    placeDao.clear();
    deviceDao.clear();
    scenarioDao.clear();
    scenarioDetDao.clear();
    loggerDao.clear();
    _logger('clearWholeTable','Cleared!');
  }

  void _logger(String key, String value) {
    doLogGlobal('app_database. H:$hashCode', key, value);
  }
}
