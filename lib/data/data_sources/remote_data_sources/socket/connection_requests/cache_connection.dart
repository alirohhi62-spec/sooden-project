import 'dart:ffi';

import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/connection_manager/connection_manager_data_model.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/socket.dart';

class CacheConnection{
    ConnectionManagerDataModel _mDataModel = ConnectionManagerDataModel();

  cache(ConnectionManagerDataModel dataModel){
    _mDataModel = dataModel;
  }

  bool hasCache() {
    return Socket.instance.isConnected() && _mDataModel.hasDataCache(false);
  }

    ConnectionManagerDataModel getData(){
    return _mDataModel;
  }
}