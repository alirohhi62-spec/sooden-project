import 'package:floor/floor.dart';

@Entity(tableName: Scenario.tableName)
class Scenario {
  @PrimaryKey(autoGenerate: true)
  int? id;

  int? locationId;
  String? floor;
  String? place;
  String? name;


  Scenario({
    this.id,
    this.locationId,
    this.name,
    this.floor,
    this.place
  });

  static const tableName = 'scenarios';
}
