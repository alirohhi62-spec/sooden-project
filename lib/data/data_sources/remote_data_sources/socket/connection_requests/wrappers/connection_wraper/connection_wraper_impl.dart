import 'package:bms/domain/store_ip_config/store_ip_config_usecase.dart';
import 'package:bms/domain/store_ip_config/store_ip_config_usecase_impl.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../../../../../../core/eventbus/event_bus_const.dart';
import '../../../../../../../core/eventbus/event_bus_model.dart';
import '../../../../../../../core/utils/globals.dart';
import '../../../../../../enums/connection_error_code.dart';
import '../../../../../../repositories/location_repository.dart';
import '../../../../../local_data_sources/database/model/location.dart';
import '../../result.dart';
import '../connection_manager/connection_manager_data_model.dart';
import '../connection_manager/connection_manager_impl.dart';
import 'connection_wraper.dart';

class ConnectionWrapperImpl extends ConnectionWrapper {
  Location? _mCurrLocations;
  late Function(Result) _mResultCallback;

  // Private constructor
  ConnectionWrapperImpl._privateConstructor();

// Static private instance
  static final ConnectionWrapperImpl _instance = ConnectionWrapperImpl._privateConstructor();

  // Public static method to return the instance of the class
  static ConnectionWrapperImpl get instance => _instance;

  @override
  void requestForConnection(Function(Result) resultCallback) async {
    _mResultCallback = resultCallback;
    _doRequestForConnection();
  }

  _doRequestForConnection() async {
    setLoading();
    await _getUserSelectedLocation();
    _manageConnect();
  }

  void setLoading() {
    _mResultCallback.call(Result.loading());
    _logger('_sendEventStartConnecting', 'event: EventBusConst.eventSocketConnecting');
  }

  _getUserSelectedLocation() async {
    _mCurrLocations = await Get.find<LocationRepository>().getUserSelectedLocation();
    _logger('_getUserSelectedLocation', '_mCurrLocations: $_mCurrLocations');
  }

  void _manageConnect() {
    if (_mCurrLocations != null) {
      _doConnect();
    } else {
      _mResultCallback.call(Result.failure(ConnectionErrorCode.emptyLocation));
    }
  }

  void _doConnect() {
    _logger('_doConnect', 'Method Called');
    ConnectionManagerImpl.instance.setData(_onResultCallback).connectByLocation(_mCurrLocations!);
  }

  _onResultCallback(Result result) async {
    if(result.isSuccess){
      await _collectIpData(result.successValue);
      (result.successValue as ConnectionManagerDataModel).referenceLocation = _mCurrLocations;
    }
    _mResultCallback.call(result);
  }

  _collectIpData(ConnectionManagerDataModel dataModel) async {
    _logger('_collectIpData', dataModel.getIpConfig().toString());

    StoreIpConfigDataUsecaseImpl().storeData(_mCurrLocations, dataModel.getIpConfig());
  }

  void _logger(String key, String value) {
    doLogGlobal('ConnectionWrapper. H:$hashCode', key, value);
  }
}
