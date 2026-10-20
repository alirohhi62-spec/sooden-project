import 'package:bms/data/data_sources/local_data_sources/database/app_database.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/logger.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/globals.dart';
import 'logger_repo.dart';

class LoggerRepoImpl extends LoggerRepo {
  LoggerRepoImpl() {
    if (!isLoggerEnable) {
      return;
    }

  }

  void addLog(String event, String className, String methodName, String value) async {
    if (Get.isRegistered<AppDatabase>()) {
      await Get.find<AppDatabase>().loggerDao.insert(Logger(
          time: getCurrentTime(),
          className: className,
          methodName: methodName,
          value: value));
    }
  }

  String getCurrentTime() {
    var now = DateTime.now();
    var formatter = DateFormat('HH:mm:ss.SSS');
    return formatter.format(now);
  }

  @override
  Future<List<Logger>> getLogs() {
    return Get.find<AppDatabase>().loggerDao.getLogs();
  }

  @override
  clearLogs() async {
    await Get.find<AppDatabase>().loggerDao.clear();
  }

  void _logger(String key, String value) {
    doLogGlobal('logger_repo_impl. H:$hashCode', key, value);
  }
}
