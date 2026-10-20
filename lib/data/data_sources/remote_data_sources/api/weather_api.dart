

import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';

import '../../../model/WeatherModel.dart';
part 'weather_api.g.dart';
@RestApi()
abstract class WeatherApi {
  factory WeatherApi(Dio dio,{String baseUrl}) = _WeatherApi;

  @GET('/forecast')
  Future<WeatherModel> getWeather(
      @Query('latitude') double latitude,
      @Query('longitude') double longitude,
      @Query('current') String current,
      );


}