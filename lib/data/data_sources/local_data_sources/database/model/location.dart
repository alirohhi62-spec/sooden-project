import 'package:floor/floor.dart';

@Entity(tableName: Location.tableName)
class Location{

  @PrimaryKey(autoGenerate: true)
  int? id;
  String? name;
  int? port;
  String? panelWifiName;
  String? panelWifiPassword;
  String? mac;
  String? modemName;
  String? modemPassword;
  String? panelIpOnModem;
  String? staticIp;
  bool? isSelected;

  Location({
    this.id,
    this.name,
    this.port,
    this.panelWifiName,
    this.panelWifiPassword,
    this.mac,
    this.modemName,
    this.modemPassword,
    this.panelIpOnModem,
    this.staticIp,
    this.isSelected,
  });

  static const tableName = 'locations';
}