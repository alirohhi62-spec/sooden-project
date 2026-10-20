import 'package:json_annotation/json_annotation.dart';

import 'WeatherCurrentModel.dart';

part 'WeatherModel.g.dart';

@JsonSerializable()
class WeatherModel{
  double latitude;
  double longitude;
  String timezone;
  WeatherCurrentModel? current;




  factory WeatherModel.fromJson(Map<String, dynamic> json) => _$WeatherModelFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherModelToJson(this);

  WeatherModel(this.latitude, this.longitude, this.timezone, this.current);

}