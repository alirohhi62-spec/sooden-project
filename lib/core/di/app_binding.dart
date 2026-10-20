import 'package:bms/core/utils/globals.dart';
import 'package:bms/data/data_sources/remote_data_sources/api/weather_api.dart';
import 'package:bms/data/data_sources/remote_data_sources/config/dio_client.dart';
import 'package:bms/data/data_sources/remote_data_sources/remote_data/weather_remote_data_source_impl.dart';
import 'package:bms/data/repositories/device_repository.dart';
import 'package:bms/data/repositories/location_repository.dart';
import 'package:bms/data/repositories/logger/logger_repo_impl.dart';
import 'package:bms/data/repositories/scenario_repository.dart';
import 'package:bms/data/repositories/weather/weather_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

class AppBindings implements Bindings {
  @override
  void dependencies() {
    if (isLoggerEnable) {
      Get.put(LoggerRepoImpl());
    }

    Get.lazyPut(() => DeviceRepository());
    Get.lazyPut(() => LocationRepository());
    Get.lazyPut(() => ScenarioRepository());
    late Dio dio = buildDioClient(WEATHER_BASE_URL);
    Get.lazyPut(() => WeatherApi(dio));
    Get.lazyPut(() => WeatherRemoteDataSourceImpl());
    Get.lazyPut(() => WeatherRepositoryImpl());
  }
}
