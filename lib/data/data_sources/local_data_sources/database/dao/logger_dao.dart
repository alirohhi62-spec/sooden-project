
import 'package:bms/data/data_sources/local_data_sources/database/dao/base_dao.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/logger.dart';

import 'package:floor/floor.dart';

@dao
abstract class LoggerDao extends BaseDao<Logger> {
  LoggerDao() : super(Logger.tableName);

  @Query('select  * from logger')
  Future<List<Logger>> getLogs();
}