import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/connection_manager/connection_manager_data_model.dart';

import '../../data/data_sources/local_data_sources/database/model/location.dart';

abstract class StoreIpConfigDataUsecase{

 storeData(Location? currLocation,IpConfigModel ipConfigModel);

}