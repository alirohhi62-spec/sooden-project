import 'package:floor/floor.dart';

import '../../../../enums/place_code.dart';

@Entity(tableName: Place.tableName)
class Place {
  @PrimaryKey(autoGenerate: true)
  int? id;
  int? locationId;
  String? floor;
  String? code;
  String? name;

  Place({
    this.id,
    required this.locationId,
    required this.floor,
    required this.code,
    required this.name,
  });

  getName() {
    if (name != null) {
      return name;
    }

    var count='';
    if (code!.length > 1) {
      count = code!.substring(1,code!.length);
    }
    return '${PlaceCode.get(code!).title!} $count';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Place &&
          runtimeType == other.runtimeType &&
          locationId == other.locationId &&
          floor == other.floor &&
          code == other.code;

  @override
  int get hashCode => locationId.hashCode ^ floor.hashCode ^ code.hashCode;

  static const tableName = 'places';
}
