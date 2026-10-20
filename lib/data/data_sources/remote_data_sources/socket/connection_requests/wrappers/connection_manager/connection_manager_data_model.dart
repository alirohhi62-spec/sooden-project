import 'package:bms/core/utils/communication_constants.dart';

import '../../../../../local_data_sources/database/model/location.dart';
import '../new_connection_wraper/new_location_data_model.dart';

enum ConnectionManagerModeEnum { gettingIp, queryFloorsCount, gettingAFloor, userData, done }

class IpConfigModel {
  IpConfigModel({this.macAddress, this.ipPanelOnModem, this.modemWifiName});

  String? macAddress;
  String? ipPanelOnModem;
  String? modemWifiName;

  @override
  String toString() {
    return 'macAddress: $macAddress => \n'
        'ipPanelOnModem: $ipPanelOnModem  => \n'
        'modemWifiName: $modemWifiName =|';
  }
}

class ConnectionManagerDataModel {
  static const ONE_FLOOR = 1;
  Location? referenceLocation;
  NewLocationDataModel? newLocationDataModel;
  String? ipToConnect;
  int? portToConnect;

  IpConfigModel _ipConfigModel = IpConfigModel();
  int _floorsCount = -1;
  final List<String> _floorsData = List.empty(growable: true);

  reInitValues(){
    _floorsCount = -1;
    _floorsData.clear();
    _ipConfigModel= IpConfigModel();
  }

  bool hasDataToConnect() {
    return ipToConnect != null && portToConnect != null;
  }

  setIpConfig(IpConfigModel ipConfigMode) {
    _ipConfigModel = ipConfigMode;
  }

  getIpConfig() {
    return _ipConfigModel;
  }

  setFloorCount(int newFloorCount) {
    _floorsCount = newFloorCount;
  }

  bool allFloorsDataReceived() {
    return _floorsCount == _floorsData.length;
  }

  addAFloor(String floorData) {
    _floorsData.add(floorData);
  }

  String getFloorAsSingleString() {
    if (_floorsCount == ONE_FLOOR) {
      return _floorsData[0];
    } else {
      return _convertFloorsToSingleLine();
    }
  }

  String _convertFloorsToSingleLine() {
    var floorStr = '';
    for (var value in _floorsData) {
      value.replaceAll('++', '');
      floorStr += value;
    }
    return floorStr += '++';
  }

  String? getNextFloor() {
    if (allFloorsDataReceived()) return null;

    if (_floorsCount == ONE_FLOOR) {
      return SocketConstants.floor;
    } else {
      return '${SocketConstants.floor}${_floorsData.length}';
    }
  }

  bool hasDataCache(bool isRequestByLocationToAvoidGettingMoreData) {
    if (!isRequestByLocationToAvoidGettingMoreData) {
      return _ipConfigModel.macAddress != null && _floorsData.isNotEmpty;
    } else {
      return _ipConfigModel.macAddress != null;
    }
  }

  bool isNewLocation() {
    return newLocationDataModel != null;
  }
}
