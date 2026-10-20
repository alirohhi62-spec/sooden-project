import 'dart:async';
import 'dart:convert';

import 'package:bms/core/utils/globals.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/tcp_socket_connection.dart';

import '../../../../core/utils/communication_constants.dart';
import 'connection_keeper.dart';
import 'connection_requests/result.dart';

class _QueuedCommand {
  final List<int> data;
  final DateTime createdAt;

  _QueuedCommand(this.data) : createdAt = DateTime.now();
}

/// لایه‌ی سوکت اپ.
///
/// تغییرات نسبت به نسخه‌ی قبل:
/// - فرمان‌ها دیگر بی‌صدا دور ریخته نمی‌شوند: در یک صف قرار می‌گیرند و با
///   فاصله‌ی حداقل [SocketConstants.minSendGapMs] ارسال می‌شوند.
/// - اگر اتصال لحظه‌ای قطع باشد، فرمان چند ثانیه در صف می‌ماند و بعد از
///   اتصال دوباره ارسال می‌شود.
/// - قطعی و دریافت داده به [ConnectionKeeper] اطلاع داده می‌شود.
class Socket {
  TcpSocketConnection? _conn;
  Function(Result)? _resultCallback;

  final List<_QueuedCommand> _queue = [];
  DateTime _lastSend = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _pumpTimer;

  Socket._privateConstructor();

  /// شنونده‌ی داده‌ی خام پنل (برای صفحه‌ی پنل‌های جدید)
  static void Function(List<int>)? rawListener;

  static final Socket _instance = Socket._privateConstructor();

  static Socket get instance => _instance;

  connect(
      {required String ip,
      required int port,
      required Function(Result) resultCallback,
      required Function onSocketConnectedCallBack,
      required Function(List<int>) callback}) async {
    _logger('connect', 'ip : $ip - port: $port');

    _conn?.disconnect();
    _conn = TcpSocketConnection();
    _resultCallback = resultCallback;

    dataCallback(List<int> data) async {
      ConnectionKeeper.instance.onDataReceived();
      rawListener?.call(data);
      callback.call(data);
    }

    onConnected() {
      onSocketConnectedCallBack.call();
      _pump();
    }

    _conn?.setData(ip, port, dataCallback, onConnected, _onResult);
    _conn?.onDisconnected = (code) => ConnectionKeeper.instance.onSocketLost(code);
    _conn?.enableConsolePrint(isLoggerEnable);
    _conn?.connect(500, 10);
  }

  /// نتیجه‌ی تلاش اتصال. اگر اتصال سریعِ دوباره در جریان باشد،
  /// شکست به نگهبان اتصال داده می‌شود و کاربر به صفحه‌ی خطا نمی‌رود.
  void _onResult(Result result) {
    if (result.isFailure && ConnectionKeeper.instance.consumeReconnectFailure()) {
      return;
    }
    _resultCallback?.call(result);
  }

  bool canReconnect() => _conn != null;

  bool isConnected() => _conn?.isConnected() ?? false;

  bool isConnecting() => _conn?.isTryingToConnect ?? false;

  /// اتصال سریع دوباره به همان آدرس قبلی
  void quickReconnect() {
    _logger('quickReconnect', 'Method called');
    if (_conn == null || _conn!.isConnected()) return;
    _conn!.connectQuick(
        SocketConstants.quickReconnectTimeoutMs, SocketConstants.quickReconnectAttempts);
  }

  send(List<int> command) {
    if (isLoggerEnable) {
      _logger('send', 'command : ${command.join(',')}');
    }
    _queue.add(_QueuedCommand(command));
    _pump();

    if (!isConnected()) {
      ConnectionKeeper.instance.ensureConnected();
    }
  }

  sendString(String message) {
    _logger('sendString', 'message : $message');
    send(utf8.encode(message));
  }

  /// ارسال فرمان بررسی سلامت، بدون صف و بدون ارسال دوباره
  bool sendProbe(String message) {
    if (!isConnected()) return false;
    return _conn!.sendMessage(utf8.encode(message));
  }

  void _pump() {
    _pumpTimer?.cancel();
    _pumpTimer = null;

    // فرمان‌های قدیمی دور ریخته می‌شوند تا کاری دیرهنگام و غیرمنتظره انجام نشود
    final now = DateTime.now();
    _queue.removeWhere((c) =>
        now.difference(c.createdAt).inMilliseconds > SocketConstants.queuedCommandTtlMs);

    if (_queue.isEmpty || !isConnected()) return;

    final waitMs =
        SocketConstants.minSendGapMs - now.difference(_lastSend).inMilliseconds;
    if (waitMs > 0) {
      _pumpTimer = Timer(Duration(milliseconds: waitMs), _pump);
      return;
    }

    final cmd = _queue.removeAt(0);
    if (_conn!.sendMessage(cmd.data)) {
      _lastSend = DateTime.now();
    } else {
      _queue.insert(0, cmd); // بعد از اتصال دوباره ارسال می‌شود
      return;
    }

    if (_queue.isNotEmpty) {
      _pumpTimer = Timer(const Duration(milliseconds: SocketConstants.minSendGapMs), _pump);
    }
  }

  /// بعد از اتصال دوباره صدا زده می‌شود تا صف خالی شود
  void flushQueue() => _pump();

  void clearQueue() => _queue.clear();

  disconnect() {
    _logger('disconnect', 'Method called');
    _conn?.disconnect();
  }

  destroy() {
    _logger('destroy', 'Method called');
    disconnect();
    _pumpTimer?.cancel();
    _queue.clear();
    _conn = null;
  }

  void _logger(String key, String value) {
    doLogGlobal('socket. H:$hashCode', key, value);
  }
}
