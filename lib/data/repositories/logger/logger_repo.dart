
import 'package:bms/data/data_sources/local_data_sources/database/model/logger.dart';

abstract class LoggerRepo {
  Future<List<Logger>> getLogs();
    clearLogs();
}