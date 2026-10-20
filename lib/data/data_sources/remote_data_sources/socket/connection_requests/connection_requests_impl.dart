import 'dart:async';

import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/cache_connection.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/result.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/connection_wraper/connection_wraper_impl.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/new_connection_wraper/new_location_connection_wrapper.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/new_connection_wraper/new_location_data_model.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/socket.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_keeper.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../../core/utils/communication_constants.dart';
import '../../../../../core/utils/globals.dart';
import 'connection_requests.dart';

class ConnectionRequestsImpl extends ConnectionRequests {
  bool _classLocked = false;
  final _mCacheConnection = CacheConnection();
  final _mSubjectResult = BehaviorSubject<Result>();

  // Private constructor
  ConnectionRequestsImpl._privateConstructor();

// Static private instance
  static final ConnectionRequestsImpl _instance = ConnectionRequestsImpl._privateConstructor();

  // Public static method to return the instance of the class
  static ConnectionRequestsImpl get instance => _instance;

  _unLockTheClass() {
    _logger("unLockTheClass", 'Method called');

    _classLocked = false;
  }

  _lockTheClass() {
    _classLocked = true;
    _updateTimer();
  }

  bool _isClassLocked() {
    _logger("_isClassLocked", ' _classLocked: $_classLocked');

    return _classLocked == true;
  }

  _updateTimer() {
    _logger("_updateTimer", 'Method called');
    Timer(const Duration(seconds: SocketConstants.connectionRequestsDelay), () {
      _logger("_updateTimer", 'un LockTheClass by timer');
      _unLockTheClass();
    });
  }

  @override
  BehaviorSubject<Result> multiConnectionRequest() {
    _logger("multiConnectionRequest", 'Method called');

    if (_mCacheConnection.hasCache()) {
      _mSubjectResult.add(Result.success(_mCacheConnection.getData()));
      _logger("multiConnectionRequest", 'Data from cache');
      return _mSubjectResult;
    }

    if (_isClassLocked()) return _mSubjectResult;

    _lockTheClass();

    ConnectionWrapperImpl.instance.requestForConnection((Result result) {
      if (result.isSuccess) {
        _mCacheConnection.cache(result.successValue);
      }
      _mSubjectResult.add(result);
    });
    return _mSubjectResult;
  }

  @override
  BehaviorSubject<Result> newLocationRequest(NewLocationDataModel newLocationDataModel) {
    _logger("newLocationRequest", 'Method called');

    if (_isClassLocked()) return _mSubjectResult;

    _lockTheClass();

    NewLocationConnectionWrapper((Result result) {
      if (result.isSuccess) {
        _mCacheConnection.cache(result.successValue);
      }
      _mSubjectResult.add(result);
    })
        .connect(newLocationDataModel);
    return _mSubjectResult;
  }

  @override
  reconnectRequest() {
    _logger("reconnectRequest", 'Method called');
    ConnectionKeeper.instance.ensureConnected();
  }

  /// اتصال کامل دوباره بدون قفل ۱۰ ثانیه‌ای و بدون کش؛
  /// آدرس پنل دوباره تعیین می‌شود (مثلاً بعد از تغییر شبکه).
  /// نتیجه مثل اتصال اولیه روی همان جریان [multiConnectionRequest] می‌آید.
  void forceReconnect() {
    _logger("forceReconnect", 'Method called');
    Socket.instance.disconnect();
    _lockTheClass();

    ConnectionWrapperImpl.instance.requestForConnection((Result result) {
      if (result.isSuccess) {
        _mCacheConnection.cache(result.successValue);
      }
      _mSubjectResult.add(result);
    });
  }

  @override
  void disconnect() {
    Socket.instance.disconnect();
  }

  @override
  destroyConnections() {
    _unLockTheClass();
    ConnectionKeeper.instance.reset();
    Socket.instance.destroy();
  }

  void _logger(String key, String value) {
    doLogGlobal('ConnectionRequestImpl. H:$hashCode', key, value);
  }
}
