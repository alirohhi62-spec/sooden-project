import 'package:bms/data/model/WeatherModel.dart';
import 'package:bms/data/repositories/weather/weather_repository.dart';
import 'package:get/get.dart';

import '../../data_sources/remote_data_sources/remote_data/weather_remote_data_source_impl.dart';

  class WeatherRepositoryImpl extends WeatherRepository {
  @override
  Future<WeatherModel> getWeather(double latitude, double longitude) {
   return Get.find<WeatherRemoteDataSourceImpl>().getWeather(latitude,longitude);
  }

}
