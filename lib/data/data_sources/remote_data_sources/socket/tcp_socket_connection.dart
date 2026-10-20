library tcp_socket_connection;

import 'dart:async';
import 'dart:io';

import '../../../../core/utils/globals.dart';
import '../../../enums/connection_error_code.dart';
import 'connection_requests/result.dart';

/// اتصال TCP به پنل.
///
/// تغییرات نسبت به نسخه‌ی قبل:
/// - بسته شدن اتصال (onDone) و خطاها (onError) واقعاً تشخیص داده می‌شوند.
///   قبلاً handleError روی سوکت صدا زده می‌شد ولی خروجی‌اش به جایی وصل نبود،
///   پس اپ هیچ‌وقت متوجه قطعی نمی‌شد.
/// - ارسال روی اتصال مرده به‌جای خطای بی‌صدا، قطعی را اعلام می‌کند.
/// - امکان اتصال سریع (بدون تأخیر یک‌ثانیه‌ای) برای اتصال دوباره.
class TcpSocketConnection {
  late String _ipAddress;
  late int _portAddress;
  Socket? _server;
  bool _connected = false;
  bool _logPrintEnabled = false;
  late Function _mDataCallback;
  late Function _mOnSocketConnectedCallBack;
  late Function(Result) _mResultCallback;

  /// وقتی اتصالِ برقرار شده قطع می‌شود صدا زده می‌شود (نه وقتی خودمان قطع کنیم)
  Function(ConnectionErrorCode)? onDisconnected;

  StreamSubscription? _mStreamSubscription;
  bool _isTryingToConnect = false;
  bool _closingIntentionally = false;

  setData(String ip, int port, Function dataCallback, Function onSocketConnectedCallBack,
      Function(Result) resultCallback) {
    _ipAddress = ip;
    _portAddress = port;
    _mDataCallback = dataCallback;
    _mOnSocketConnectedCallBack = onSocketConnectedCallBack;
    _mResultCallback = resultCallback;
  }

  String get ipAddress => _ipAddress;

  enableConsolePrint(bool enable) {
    _logPrintEnabled = enable;
  }

  bool get isTryingToConnect => _isTryingToConnect;

  /// اتصال اولیه (مثل قبل: هر تلاش با یک ثانیه تأخیر)
  connect(int timeOut, int attempts) async {
    _startConnecting(timeOut, attempts, const Duration(seconds: 1));
  }

  /// اتصال سریع دوباره: بدون تأخیر اولیه
  connectQuick(int timeOut, int attempts) async {
    _startConnecting(timeOut, attempts, Duration.zero);
  }

  void _startConnecting(int timeOut, int attempts, Duration delay) {
    _printData('connect', "attempts : $attempts _isTryingToConnect $_isTryingToConnect");
    if (_isTryingToConnect) return;
    if (_connected) return;

    _isTryingToConnect = true;
    _doConnect(timeOut, attempts, delay);
  }

  _doConnect(int timeOut, int attempts, Duration delay) async {
    _connectWithDelay(timeOut, delay)
        .then((_) => _onConnected())
        .catchError((_) => _onError(timeOut, attempts, delay));
  }

  _onConnected() {
    _connected = true;
    _isTryingToConnect = false;
    _closingIntentionally = false;
    _printData('_onConnected', "Socket successfully connected");

    try {
      _server?.setOption(SocketOption.tcpNoDelay, true);
    } catch (_) {}

    _listenToSocket();
    _mOnSocketConnectedCallBack.call();
  }

  void _listenToSocket() {
    _mStreamSubscription?.cancel();
    _mStreamSubscription = _server?.listen(
      (List<int> event) {
        _printData('listenToSocket', "received: ${event.join('-')}");
        _mDataCallback.call(event);
      },
      onError: (error) {
        _printData('listenToSocket', 'onError: $error');
        _handleLostConnection(error is SocketException
            ? ConnectionErrorCode.socketClosedByOtherSide
            : ConnectionErrorCode.errorInSocket);
      },
      onDone: () {
        _printData('listenToSocket', 'onDone (connection closed)');
        _handleLostConnection(ConnectionErrorCode.socketClosedByOtherSide);
      },
      cancelOnError: true,
    );
  }

  void _handleLostConnection(ConnectionErrorCode code) {
    final wasConnected = _connected;
    _connected = false;
    _mStreamSubscription?.cancel();
    _mStreamSubscription = null;
    try {
      _server?.destroy();
    } catch (_) {}
    _server = null;

    if (_closingIntentionally) {
      _closingIntentionally = false;
      return;
    }
    if (wasConnected) onDisconnected?.call(code);
  }

  _onError(int timeOut, int attempts, Duration delay) {
    // آدرس هم در گزارش نوشته می‌شود تا علت وصل نشدن با یک نگاه معلوم باشد
    _printData('_onError', "$attempts attempt: Socket not connected (Timeout reached) to $_ipAddress:$_portAddress");

    if (attempts <= 0) {
      _isTryingToConnect = false;
      _mResultCallback.call(Result.failure(ConnectionErrorCode.timeoutNotConnected));
    } else {
      _doConnect(timeOut, attempts - 1, delay);
    }
  }

  Future _connectWithDelay(int timeOut, Duration delay) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    _server = await Socket.connect(_ipAddress, _portAddress,
        timeout: Duration(milliseconds: timeOut));
  }

  /// قطع عمدی اتصال (مثلاً بعد از ۳۰ ثانیه در پس‌زمینه). قطعی گزارش نمی‌شود.
  void disconnect() {
    _printData('disconnect', "Method called");
    _isTryingToConnect = false;

    if (_server != null) {
      _closingIntentionally = true;
      try {
        _mStreamSubscription?.cancel();
        _mStreamSubscription = null;
        _server?.destroy();
      } catch (exception) {
        _printData('disconnect', "ERROR : $exception");
      }
      _server = null;
    }
    _closingIntentionally = false;
    _connected = false;
  }

  bool isConnected() {
    return _connected;
  }

  /// true یعنی داده تحویل سوکت شد
  bool sendMessage(List<int> data) {
    if (_server != null && _connected) {
      try {
        _server!.add(data);
        return true;
      } catch (e) {
        _printData('sendMessage', 'send failed: $e');
        _handleLostConnection(ConnectionErrorCode.errorInSocket);
        return false;
      }
    }
    _printData('sendMessage', "Socket not connected; message not sent");
    return false;
  }

  void _printData(String where, String data) {
    if (_logPrintEnabled) {
      doLogGlobal('tcp_socket_connection. H:$hashCode', where, data);
    }
  }
}
