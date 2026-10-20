// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'WeatherCurrentModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherCurrentModel _$WeatherCurrentModelFromJson(Map<String, dynamic> json) =>
    WeatherCurrentModel(
      json['time'] as String,
      (json['temperature_2m'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$WeatherCurrentModelToJson(
        WeatherCurrentModel instance) =>
    <String, dynamic>{
      'time': instance.time,
      'temperature_2m': instance.temperature_2m,
    };
