import 'package:bms/data/model/WeatherModel.dart';


abstract class WeatherRepository {
  Future<WeatherModel> getWeather(double latitude, double longitude);
}
