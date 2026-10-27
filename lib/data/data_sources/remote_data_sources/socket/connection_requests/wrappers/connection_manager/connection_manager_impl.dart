import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/result.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/connection_manager/connection_manager_data_model.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/connection_manager/ip_manager/ip_config.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/socket.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_keeper.dart';
import 'package:bms/presentation/screens/error_gps/error_gps_screen.dart';
import 'package:get/get.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:bms/data/enums/connection_error_code.dart';

import '../../../../../../../core/utils/communication_constants.dart';
import '../../../../../../../core/utils/globals.dart';
import '../../../../../local_data_sources/database/model/location.dart';
import '../new_connection_wraper/new_location_data_model.dart';
import 'connection_manager.dart';
import 'manage_getting_config/manage_getting_config_impl.dart';
import 'manage_gps/location_enable_manager.dart';
import 'observe_connection/observe_connection.dart';
import 'package:bms/core/utils/wifi_bind.dart';

class ConnectionManagerImpl implements ConnectionManager {
  late final mSocket = Socket.instance;
  final ConnectionManagerDataModel _mDataModel = ConnectionManagerDataModel();
  late Function(Result) _mResultCallback;
  Location? _mLocation;
  ObserveConnection? _mObserveConnection;
  final ManageGettingConfigImpl _mManageGettingConfig = ManageGettingConfigImpl.instance;

// Private constructor
  ConnectionManagerImpl._privateConstructor();

// Static private instance
  static final ConnectionManagerImpl _instance = ConnectionManagerImpl._privateConstructor();

  // Public static method to return the instance of the class
  static ConnectionManagerImpl get instance => _instance;

  @override
  ConnectionManagerImpl setData(Function(Result) resultCallback, {NewLocationDataModel? model}) {
    _mResultCallback = resultCallback;
    _mDataModel.newLocationDataModel = model;
    _mManageGettingConfig.setData(_mDataModel, _mResultCallback);

    return this;
  }

  @override
  void connectByLocation(Location location) async {
    _logger('connectByLocation', 'location.name : ${location.name}');
    _mLocation = location;

    _manageConnect();
  }

  @override
  connect() async {
    _logger('connect', 'method called');
    _mLocation = null;
    _manageConnect();
  }

  _manageConnect() async {
    _logger('_manageConnect', 'Method called');

    if (await _checkGPS()) {
      await _initIpPort();
      if (_mDataModel.hasDataToConnect()) {
        _logger('_manageConnect', 'Start fresh connecting');
        _doConnect();
      }
    }
  }

  _checkGPS() async {
    var status = await LocationEnableManager().isLocationEnabled();

    if (!status) {
      Get.offAll(() => const ErrorGpsScreen());
      return false;
    } else {
      return true;
    }
  }

  _initIpPort() async {
    _logger('_initIpPort', '_mLocation = $_mLocation');

    if (_mLocation != null) {
      await _getIpPortFromLocation(_mLocation);
    } else if (_mDataModel.newLocationDataModel?.ipStatic != null &&
        (_mDataModel.newLocationDataModel?.ipStatic?.isNotEmpty ?? false)) {
      await WifiBind.set(false);
      _getIpPortFromIpStatic();
    } else {
      await WifiBind.set(true);                      // مکان جدید: گوشی روی وای‌فای پنل (192.168.4.1)
      _getIpPortFromConst();
    }
  }

  _doConnect() async {
    await mSocket.connect(
        ip: _mDataModel.ipToConnect!,
        port: _mDataModel.portToConnect!,
        resultCallback: _mResultCallback,
        onSocketConnectedCallBack: _onSocketConnected,
        callback: (data) {
          _mManageGettingConfig.onDataListener(data);
        });
  }

  _getIpPortFromLocation(location) async {
    String? gottenIp = await IpConfig().getConnectionInfo(location, _mResultCallback);
    _logger('_getIpPortFromLocation', 'gottenIp = $gottenIp');

    if (gottenIp == null) {
      _mDataModel.ipToConnect = null;

      _logger('_getIpPortFromLocation', 'An error, gottenIp is null');
      _mResultCallback.call(Result.failure( ConnectionErrorCode.gottenIpFromLocationIsNull));

      return false;
    }

    _mDataModel.ipToConnect = gottenIp;
    _mDataModel.portToConnect = location.port!;
  }

  _getIpPortFromIpStatic() {
    _logger('_getIpPortFromIpStatic', 'ipToConnect = ${_mDataModel.newLocationDataModel?.ipStatic}');

    _mDataModel.ipToConnect = _mDataModel.newLocationDataModel?.ipStatic;
    _mDataModel.portToConnect = SocketConstants.port;
  }

  _getIpPortFromConst() {
    _logger('_getIpPortFromConst', 'ipToConnect = ${SocketConstants.ip}');

    _mDataModel.ipToConnect = SocketConstants.ip;
    _mDataModel.portToConnect = SocketConstants.port;
  }

  _onSocketConnected() {
    _logger('_onSocketConnected', 'isConnected : ${mSocket.isConnected()}');
    if (mSocket.isConnected()) {
      if (ConnectionKeeper.instance.isQuickReconnecting) {
        // اتصال دوباره به همان پنل: تنظیمات قبلاً دریافت شده، فقط اتصال برقرار شود
        ConnectionKeeper.instance.onQuickReconnected();
        return;
      }
      _mManageGettingConfig.startTheJob();
      _initConnectionObserver();
    } else {
      _logger('_onSocketConnected', 'unexpectedly mSocket is not connected!');
    }
  }

  void _initConnectionObserver() async {
    _logger('_initConnectionObserver', 'Method Called');
    final networkInfo = NetworkInfo();

    String? wifiBSSID = await networkInfo.getWifiBSSID();

    if (_mObserveConnection == null) {
      _mObserveConnection = ObserveConnection();
    } else {
      _mObserveConnection?.cancel();
    }
    _mObserveConnection?.subscribe(wifiBSSID);
  }

  void _logger(String key, String value) {
    doLogGlobal('connection_manager_impl. H:$hashCode', key, value);
  }
}
