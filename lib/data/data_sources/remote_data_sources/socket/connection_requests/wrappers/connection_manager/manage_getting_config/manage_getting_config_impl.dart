import 'dart:async';
import 'dart:convert';

import 'package:bms/data/data_sources/remote_data_sources/socket/socket.dart';
import 'package:bms/data/enums/connection_error_code.dart';
import 'package:bms/domain/extract_ip_config/extract_ip_config_usecase_impl.dart';

import '../../../../../../../../core/utils/communication_constants.dart';
import '../../../../../../../../core/utils/globals.dart';
import '../../../result.dart';
import '../../new_connection_wraper/manage_new_locattion_data_impl.dart';
import '../connection_manager_data_model.dart';
import 'data_receiver/handle_receive_data.dart';
import 'manage_getting_config.dart';

class ManageGettingConfigImpl extends ManageGettingConfig {
  late final mSocket = Socket.instance;
  ConnectionManagerModeEnum _mMode = ConnectionManagerModeEnum.gettingIp;
  late Function(Result) _mResultCallback;
  final HandleReceiveData _mReceiveData = HandleReceiveData();
  late ConnectionManagerDataModel _mDataModel;
  Timer? _mCurrentTimeout;
  late List<ConnectionManagerModeEnum> _mArrayModesAllowToHave;

  /// پیام‌های بلند تنظیمات ممکن است در چند تکه‌ی TCP برسند؛ اینجا جمع می‌شوند
  final List<int> _frameBuffer = [];
  bool _collectingFrame = false;

  /// اگر پیام علامت پایان «+» نداشته باشد (مثلاً جواب تعداد طبقات «#T»)،
  /// بعد از این مدت سکوت، همان داده‌ی رسیده کامل در نظر گرفته می‌شود
  static const int _frameIdleMs = 300;
  Timer? _frameIdleTimer;

// Private constructor
  ManageGettingConfigImpl._privateConstructor();

// Static private instance
  static final ManageGettingConfigImpl _instance = ManageGettingConfigImpl._privateConstructor();

  // Public static method to return the instance of the class
  static ManageGettingConfigImpl get instance => _instance;

  @override
  ManageGettingConfigImpl setData(ConnectionManagerDataModel dataModel,
      Function(Result) resultCallback) {
    _mResultCallback = resultCallback;
    _mDataModel = dataModel;
    _mDataModel.reInitValues();
    return this;
  }

  @override
  startTheJob() {
    _logger('startTheJob', 'method called');

    _initArrayModes(_mDataModel.isNewLocation());
    _frameIdleTimer?.cancel();
    _frameBuffer.clear();
    _collectingFrame = false;
    changeMode(ConnectionManagerModeEnum.gettingIp);
  }

  _initArrayModes(bool isNewLocation) {
    if (isNewLocation) {
      _mArrayModesAllowToHave = [
        ConnectionManagerModeEnum.gettingIp,
        ConnectionManagerModeEnum.queryFloorsCount,
        ConnectionManagerModeEnum.gettingAFloor,
        ConnectionManagerModeEnum.userData,
        ConnectionManagerModeEnum.done
      ];
    } else {
      _mArrayModesAllowToHave = [
        ConnectionManagerModeEnum.gettingIp,
        ConnectionManagerModeEnum.userData,
        ConnectionManagerModeEnum.done
      ];
    }
  }

  _doActionOnCurrentMode() {
    _logger('doActionOnCurrentMode', '_mMode : $_mMode');

    switch (_mMode) {
      case ConnectionManagerModeEnum.gettingIp:
        requestIp();
        break;
      case ConnectionManagerModeEnum.queryFloorsCount:
        requestQueryFloorsCount();
        break;
      case ConnectionManagerModeEnum.gettingAFloor:
        requestOneFloor();
        break;
      case ConnectionManagerModeEnum.userData:
        onUserData();
        break;
      case ConnectionManagerModeEnum.done:
      // do nothing
        break;
    }
  }

  @override
  void requestIp() {
    //@M_IP
    sendSocketByDelay(SocketConstants.requestIp);
  }

  @override
  void requestQueryFloorsCount() {
    //@M_F_C
    sendSocketByDelay(SocketConstants.requestQueryFloorsCount);
  }

  @override
  void requestOneFloor() {
    _logger('requestOneFloor','Next floor is : ${_mDataModel.getNextFloor() != null}');

    if (_mDataModel.getNextFloor() != null) {
      sendSocketByDelay(SocketConstants.requestAFloor + _mDataModel.getNextFloor()!);
    }
  }

  void sendSocketByDelay(String message) {
    _logger('sendSocketByDelay: Create a Timer', 'message: $message.');

    Timer(const Duration(milliseconds: SocketConstants.sendSocketByDelay), () {
      _logger('sendSocketByDelay: Timer called', 'message: $message.');
      mSocket.sendString(message);
      createTimeOut();
    });
  }

  void createTimeOut() {
    _logger('createTimeOut', 'Timeout updated.');
    _mCurrentTimeout?.cancel();

    _mCurrentTimeout = Timer(const Duration(seconds: SocketConstants.manageGettingConfigTimeOut), () {
      _logger('createTimeOut', 'timeout happen!.');
      _mResultCallback.call(Result.failure(ConnectionErrorCode.timeoutNotReceivedData));
    });
  }

  void cancelTimeout() {
    _logger('cancelTimeout', 'Timeout cancelled.');

    _mCurrentTimeout?.cancel();
    _mCurrentTimeout=null;
  }

  @override
  void onDataListener(List<int> data) {
    _logger('onDataListener', 'data : ${data.join('-')}');
    if (data.isEmpty) return;

    try {
      // ادامه‌ی پیامی که در چند تکه می‌رسد
      if (_collectingFrame) {
        _appendFrame(data);
        return;
      }

      final bool sessionDone = _mMode == ConnectionManagerModeEnum.done;
      String command = String.fromCharCode(data[0]);
      switch (command) {
        case '%':
          // بعد از پایان دریافت تنظیمات، این پیام جواب بررسی سلامت اتصال است
          if (sessionDone) return;
          onIpReceived(data);
          break;

        case '#':
          if (sessionDone) return;
          _appendFrame(data);
          break;

        case '@':
          _mReceiveData.handleStatusData(data);
          break;

        default:
          _logger('connect', 'Unknown Data: ${data.join('|')}');
          // وقتی اپ در حال کار است، داده‌ی ناشناخته نباید کاربر را به صفحه‌ی خطا ببرد
          if (sessionDone) return;
          cancelTimeout();
          _mResultCallback.call(Result.failure(ConnectionErrorCode.unknownData));
          break;
      }
    } catch (e) {
      _logger('connect', 'Caught an exception: $e');
    }
  }

  /// تکه‌ها جمع می‌شوند تا پیام با «+» تمام شود.
  /// بعضی جواب‌های پنل (مثل «#T» برای تعداد طبقات) علامت پایان ندارند؛
  /// برای آن‌ها، اگر ۳۰۰ میلی‌ثانیه داده‌ی تازه‌ای نرسد، پیام کامل حساب می‌شود.
  void _appendFrame(List<int> data) {
    _collectingFrame = true;
    _frameBuffer.addAll(data);
    _frameIdleTimer?.cancel();

    if (_isFrameComplete()) {
      _finishFrame();
    } else {
      _frameIdleTimer = Timer(const Duration(milliseconds: _frameIdleMs), _finishFrame);
    }
  }

  void _finishFrame() {
    _frameIdleTimer?.cancel();
    _frameIdleTimer = null;
    if (!_collectingFrame) return;
    final frame = List<int>.from(_frameBuffer);
    _frameBuffer.clear();
    _collectingFrame = false;
    onDataFloorReceived(frame);
  }

  bool _isFrameComplete() {
    for (int i = _frameBuffer.length - 1; i >= 0; i--) {
      final c = _frameBuffer[i];
      if (c == 0x0A || c == 0x0D || c == 0x20) continue; // فاصله یا خط جدید
      return c == 0x2B; // '+'
    }
    return false;
  }

  /// Expected : %44:17:93:3a:1e:37+%S=1,192.168.0.76 ?
  @override
  void onIpReceived(List<int> data) async {
    cancelTimeout();
    _mDataModel.setIpConfig(await ExtractIpConfigDataUsecaseImpl().parseData(data));
    changeMode(ConnectionManagerModeEnum.queryFloorsCount);
  }

  @override
  void onDataFloorReceived(List<int> data) {
    cancelTimeout();
    _logger('onDataFloorReceived', '_mMode: $_mMode');

    if (_mMode == ConnectionManagerModeEnum.queryFloorsCount) {
      onQueryFloorsCountReceived(data);
    } else {
      onOneFloorDataReceived(data);
    }
  }

  /// Expected data #T1#T2#T3#T4++ Or #T++
  @override
  void onQueryFloorsCountReceived(List<int> data) {
    _logger('onQueryFloorsCountReceived', 'Method called');

    var floorArray =
    RegExp(r'T\d*').allMatches(utf8.decode(data)).map((match) => match.group(0)).toList();
    _mDataModel.setFloorCount(floorArray.length);
    changeMode(ConnectionManagerModeEnum.gettingAFloor);
    // request as loop for the floors
  }

  /// Expected data :
  /// 1. #T*A1/Uaaaaaaaaaa/Vp1*L+#X1*Z1++
  /// 2. #T0*A/Uaabbcd/Vqqpp/Wsw*B/Uaabbbdek/Vqp/Wsw*C/Uabde/Ww*E/Uabcd/Vqp/Wsw*G/Ub*I/Ub*J/Ubcg*K/Ubcg++
  /// 3. #T1*B/Uaabbcd/Vq/Wsw*C/Uabbe/Ww*E/Uabcd/Vq/Wsw*C/Uabbe/Ww*E/Uabcd/Vq/Wsw*C/Uabbe/Ww*E/Uabcd/Vq/Wsw*G/Uc*I/Ub*J/Ubcg*J/Ubcg*K/Ubcg++
  @override
  void onOneFloorDataReceived(List<int> data) {
    _mDataModel.addAFloor(utf8.decode(data));
    _manageEndOfTheFloors();
  }

  void _manageEndOfTheFloors() {
    _logger('_manageEndOfTheFloors', 'allFloorsDataReceived() ${_mDataModel.allFloorsDataReceived()}');

    if (_mDataModel.allFloorsDataReceived()) {
      // End.
      changeMode(ConnectionManagerModeEnum.userData);
    } else {
      // Looking for other floor
      changeMode(ConnectionManagerModeEnum.gettingAFloor);
    }
  }

  @override
  void changeMode(ConnectionManagerModeEnum newMode) {
    _logger('changeMode', 'newMode : $newMode');

    _manageRequestModeIsAllowed(newMode);
    _doActionOnCurrentMode();
  }

  _manageRequestModeIsAllowed(ConnectionManagerModeEnum newMode) {
    if (_mArrayModesAllowToHave.contains(newMode)) {
      _mMode = newMode;
    } else {
      _mMode = ConnectionManagerModeEnum.userData;
    }
  }

  @override
  onUserData() {
    changeMode(ConnectionManagerModeEnum.done);

    if (_mDataModel.isNewLocation()) {
      _storeData();
    }else {
      _mResultCallback.call(Result.success(_mDataModel));
    }
  }

  _storeData() {
      MangeNewLocationDataImpl mMangeNewData = MangeNewLocationDataImpl(_mResultCallback);
      mMangeNewData.startWorking(_mDataModel);
  }

  void _logger(String key, String value) {
    doLogGlobal('manage_getting_config_impl. H:$hashCode', key, value);
  }
}
