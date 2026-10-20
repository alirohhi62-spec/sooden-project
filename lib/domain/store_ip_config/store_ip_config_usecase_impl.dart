import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/connection_manager/connection_manager_data_model.dart';
import 'package:bms/data/repositories/location_repository.dart';
import 'package:bms/domain/store_ip_config/store_ip_config_usecase.dart';
import 'package:get/get.dart';

import '../../data/data_sources/local_data_sources/database/model/location.dart';

class StoreIpConfigDataUsecaseImpl extends StoreIpConfigDataUsecase {
  @override
  storeData(Location? currLocation,IpConfigModel ipConfigModel) {
    currLocation?.panelIpOnModem = ipConfigModel.ipPanelOnModem;
    currLocation?.mac = ipConfigModel.macAddress;
    currLocation?.modemName = ipConfigModel.modemWifiName;
    Get.find<LocationRepository>().updateLocation(currLocation!);
  }
}
