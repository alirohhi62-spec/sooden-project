import 'package:bms/data/data_sources/remote_data_sources/api/weather_api.dart';
import 'package:bms/data/data_sources/remote_data_sources/remote_data/weather_remote_data_source.dart';
import 'package:bms/data/model/WeatherModel.dart';
import 'package:get/get.dart';


class WeatherRemoteDataSourceImpl extends WeatherRemoteDataSource {
  @override
  Future<WeatherModel> getWeather(double latitude, double longitude) async {
    return Get.find<WeatherApi>().getWeather(latitude,longitude,'temperature_2m');
  }

}