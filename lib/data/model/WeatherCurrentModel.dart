import 'package:json_annotation/json_annotation.dart';

part 'WeatherCurrentModel.g.dart';

@JsonSerializable()
class WeatherCurrentModel{
  String time;
  double? temperature_2m;


  factory WeatherCurrentModel.fromJson(Map<String, dynamic> json) => _$WeatherCurrentModelFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherCurrentModelToJson(this);

  WeatherCurrentModel(this.time, this.temperature_2m);
}