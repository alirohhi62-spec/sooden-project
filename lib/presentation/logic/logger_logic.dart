import 'package:bms/data/data_sources/local_data_sources/database/model/logger.dart';
import 'package:bms/data/repositories/logger/logger_repo_impl.dart';
import 'package:bms/presentation/logic/base_logic.dart';
import 'package:get/get.dart';


class LoggerLogic extends BaseLogic {
  final _loggerRepo = Get.find<LoggerRepoImpl>();

  List<Logger> logList = [];

  LoggerLogic();

  @override
  void onInit() {
    super.onInit();
    getLogs();
  }

  void getLogs() async {
    logList = await _loggerRepo.getLogs();
    update();
  }

  void clearData() async {
    await _loggerRepo.clearLogs();
    getLogs();
  }
}
