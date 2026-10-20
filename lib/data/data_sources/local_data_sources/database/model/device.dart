

import 'package:floor/floor.dart';

import '../../../../enums/device_code.dart';

@Entity(tableName: Device.tableName)
class Device{

  @PrimaryKey(autoGenerate: true)
  int? id;
  int? locationId;
  String? floor;
  String? place;
  String? headline;
  String? code;
  String? name;
  String? value;
  String? secondValue;

  Device({
    this.id,
    this.locationId,
    this.floor,
    this.place,
    this.headline,
    this.code,
    this.name,
    this.value,
    this.secondValue,
  });

  getName(){
    if(name != null){
      return name;
    }

    var count='';
    if (code!.length > 1) {
      count = code!.substring(1,code!.length);
    }
    return '${DeviceCode.get(code!).title!} $count';
  }

  static const tableName = 'devices';
}