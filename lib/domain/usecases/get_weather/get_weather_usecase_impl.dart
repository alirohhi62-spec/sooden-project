import 'package:bms/data/repositories/weather/weather_repository_impl.dart';
import 'package:get/get.dart';

import '../../../core/utils/globals.dart';
import '../user_location/user_location_usecase_impl.dart';
import 'get_weather_usecase.dart';

class GetWeatherCaseImpl extends GetWeatherCase {
  @override
  Future<String> getWeather() async {
    var position = await UserLocationUseCaseImpl().getLocation();

    var model = await Get.find<WeatherRepositoryImpl>().getWeather(position.latitude,position.longitude);

    if (model.current != null && model.current?.temperature_2m != null) {
      return '${model.current?.temperature_2m}°';
    } else {
      return 'Unable to get the weather';
    }
  }

  void _logger(String key, String value) {
    doLogGlobal('get_weather_usecase_impl. H:$hashCode', key, value);
  }

}
