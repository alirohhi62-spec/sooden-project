import 'package:bms/data/model/WeatherModel.dart';

abstract class WeatherRemoteDataSource {
  Future<WeatherModel> getWeather(double latitude, double longitude);
}