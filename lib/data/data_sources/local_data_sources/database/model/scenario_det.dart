import 'package:floor/floor.dart';

@Entity(tableName: ScenarioDet.tableName)
class ScenarioDet {
  @PrimaryKey(autoGenerate: true)
  int? id;

  int? scenarioId;
  int? deviceId;
  String? value;
  @ignore
  String? deviceName;
  @ignore
  String? headline;
  @ignore
  String? code;

  ScenarioDet({
    this.id,
    this.scenarioId,
    this.deviceId,
    this.deviceName,
    this.headline,
    this.code,
    this.value,
  });

  static const tableName = 'scenario_det';
}
