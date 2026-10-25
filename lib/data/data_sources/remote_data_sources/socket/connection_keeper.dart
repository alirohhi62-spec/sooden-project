import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/eventbus/event_bus_const.dart';
import '../../../../core/eventbus/event_bus_model.dart';
import '../../../../core/utils/communication_constants.dart';
import '../../../../core/utils/globals.dart';
import '../../../enums/connection_error_code.dart';
import 'connection_requests/connection_requests_impl.dart';
import 'socket.dart';

enum LinkState { connected, connecting, disconnected }

/// نگهبان اتصال: کاری می‌کند که کاربر قطعی را حس نکند.
///
/// - با رفتن اپ به پس‌زمینه اتصال قطع نمی‌شود؛ فقط اگر بیش از
///   [SocketConstants.backgroundKeepAliveSeconds] ثانیه در پس‌زمینه بماند، مرتب بسته
///   می‌شود تا جای گوشی‌های دیگر (پنل حداکثر ۲ اتصال می‌پذیرد) و باتری گرفته نشود.
/// - وقتی اپ روی صفحه است، هر [SocketConstants.heartbeatIntervalSeconds] ثانیه
///   سلامت اتصال بررسی می‌شود (فقط اگر در این مدت داده‌ای نرسیده باشد).
/// - با برگشت به اپ یا قطع شدن اتصال، بی‌صدا و فوری دوباره وصل می‌شود؛
///   بدون دریافت دوباره‌ی تنظیمات و بدون رفتن به صفحه‌ی خطا.
/// - فقط اگر اتصال بیش از [SocketConstants.reconnectGiveUpSeconds] ثانیه برقرار نشود،
///   صفحه‌ی خطا نمایش داده می‌شود.
class ConnectionKeeper {
  ConnectionKeeper._();

  static final ConnectionKeeper instance = ConnectionKeeper._();

  /// وضعیت اتصال برای نمایش نوار «در حال اتصال»
  final Rx<LinkState> state = LinkState.disconnected.obs;

  /// پنل سیمکارتی: وقتی true بدهد، قطع وای‌فای به صفحه‌ی «دستگاه پیدا نشد» نمی‌رود
  /// (صفحه می‌ماند و فرمان‌ها با پیامک می‌رود) و اتصال پشت صحنه دوباره امتحان می‌شود
  static bool Function()? holdOnLoss;
  /// کاربر در شروع «ادامه با سیمکارت» را قبول کرد: وای‌فای پشت صحنه امتحان می‌شود، صفحه‌ی خطا نمی‌آید
  static bool smsAccepted = false;

  /// اتصال دوباره همین الان (صفحه‌ی اصلی آن را می‌گذارد؛ برای دکمه‌ی وای‌فای پنل سیمکارتی)
  static void Function()? retryNow;
  static bool get holding => smsAccepted || (holdOnLoss?.call() ?? false);

  bool _sessionReady = false; // اتصال اولیه و دریافت تنظیمات یک بار کامل شده
  bool _inForeground = true;
  bool _quickReconnecting = false;
  bool _fullReconnecting = false;

  DateTime _lastRx = DateTime.now();
  DateTime? _probeSentAt;
  DateTime? _reconnectStartedAt;

  Timer? _backgroundTimer;
  Timer? _heartbeatTimer;
  Timer? _giveUpTimer;

  // ---------- رویدادهای اتصال اولیه ----------

  /// وقتی اتصال اولیه و دریافت تنظیمات کامل شد (از صفحه‌ی اصلی صدا زده می‌شود)
  void onSessionReady() {
    _logger('onSessionReady', '');
    _sessionReady = true;
    _fullReconnecting = false;
    _onLinkUp();
  }

  /// وقتی اتصال کامل از بین رفت (صفحه‌ی خطا، تغییر مکان، خروج)
  void reset() {
    _logger('reset', '');
    _sessionReady = false;
    _quickReconnecting = false;
    _fullReconnecting = false;
    _stopHeartbeat();
    _giveUpTimer?.cancel();
    _backgroundTimer?.cancel();
    state.value = LinkState.disconnected;
  }

  /// اتصال اولیه یک بار کامل شده است (هر قطعی بعد از این، اتصال دوباره است)
  bool get hasSession => _sessionReady;

  /// آیا در اتصال دوباره، دریافت تنظیمات باید رد شود؟
  bool get isQuickReconnecting => _sessionReady && _quickReconnecting;

  // ---------- رویدادهای سوکت ----------

  void onDataReceived() {
    _lastRx = DateTime.now();
    _probeSentAt = null;
  }

  /// سوکت دوباره وصل شد (در حالت اتصال سریع)
  void onQuickReconnected() {
    _logger('onQuickReconnected', '');
    _quickReconnecting = false;
    _onLinkUp();
    // صفحه‌های باز وضعیت دستگاه‌ها را دوباره درخواست کنند
    eventBus.fire(EventBusModel(event: EventBusConst.eventSocketReconnect));
  }

  void onSocketLost(ConnectionErrorCode code) {
    _logger('onSocketLost', '$code');
    _stopHeartbeat();
    if (!_sessionReady) return; // در اتصال اولیه، روال قبلی خطا را مدیریت می‌کند

    state.value = LinkState.disconnected;
    if (_inForeground) ensureConnected();
  }

  /// شکست تلاش اتصال. اگر مربوط به اتصال سریع باشد، اینجا مدیریت می‌شود
  /// و true برمی‌گرداند تا کاربر به صفحه‌ی خطا نرود.
  bool consumeReconnectFailure() {
    if (!_quickReconnecting) return false;
    _logger('consumeReconnectFailure', 'quick reconnect failed -> full reconnect');
    _quickReconnecting = false;
    _startFullReconnect();
    return true;
  }

  // ---------- چرخه‌ی عمر اپ ----------

  void onPaused() {
    _logger('onPaused', '');
    _inForeground = false;
    _stopHeartbeat();
    _backgroundTimer?.cancel();
    _backgroundTimer =
        Timer(const Duration(seconds: SocketConstants.backgroundKeepAliveSeconds), () {
      _logger('onPaused', 'background timeout -> close connection');
      if (!_inForeground && Socket.instance.isConnected()) {
        Socket.instance.disconnect();
        state.value = LinkState.disconnected;
      }
    });
  }

  void onResumed() {
    _logger('onResumed', '');
    _inForeground = true;
    _backgroundTimer?.cancel();
    if (!_sessionReady) return;

    if (Socket.instance.isConnected()) {
      // ممکن است سیستم‌عامل اتصال را در پس‌زمینه کشته باشد: فوراً بررسی شود
      _sendProbe();
      _startHeartbeat();
    } else {
      ensureConnected();
    }
  }

  /// تغییر شبکه (مثلاً از وای‌فای خانه به اینترنت همراه): آدرس پنل باید دوباره تعیین شود
  void onNetworkChanged() {
    _logger('onNetworkChanged', '');
    if (!_sessionReady) return;
    _stopHeartbeat();
    Socket.instance.disconnect();
    state.value = LinkState.disconnected;
    if (_inForeground) _startFullReconnect();
  }

  // ---------- اتصال دوباره ----------

  void ensureConnected() {
    if (!_sessionReady) return;
    if (Socket.instance.isConnected()) return;
    if (_quickReconnecting || _fullReconnecting || Socket.instance.isConnecting()) return;

    _logger('ensureConnected', 'start quick reconnect');
    state.value = LinkState.connecting;
    _reconnectStartedAt ??= DateTime.now();
    _armGiveUpTimer();

    if (Socket.instance.canReconnect()) {
      _quickReconnecting = true;
      Socket.instance.quickReconnect();
    } else {
      _startFullReconnect();
    }
  }

  void _startFullReconnect() {
    if (_fullReconnecting) return;
    _logger('_startFullReconnect', '');
    _stopHeartbeat();
    _fullReconnecting = true;
    state.value = LinkState.connecting;
    _reconnectStartedAt ??= DateTime.now();
    _armGiveUpTimer();
    ConnectionRequestsImpl.instance.forceReconnect();
  }

  /// نتیجه‌ی اتصال کامل دوباره (از صفحه‌ی اصلی)
  void onFullReconnectFailed() {
    _logger('onFullReconnectFailed', '');
    _fullReconnecting = false;
  }

  void _armGiveUpTimer() {
    _giveUpTimer?.cancel();
    final elapsed = DateTime.now().difference(_reconnectStartedAt!).inSeconds;
    final left = SocketConstants.reconnectGiveUpSeconds - elapsed;
    _giveUpTimer = Timer(Duration(seconds: left > 0 ? left : 0), () {
      if (Socket.instance.isConnected()) return;
      _quickReconnecting = false;
      _fullReconnecting = false;
      _reconnectStartedAt = null;
      if (holding) {
        _logger('_giveUp', 'SIM panel: stay (SMS), try again in 10 s');
        state.value = LinkState.disconnected;
        Timer(const Duration(seconds: 10), ensureConnected);
        return;
      }
      _logger('_giveUp', 'could not reconnect -> show error screen');
      eventBus.fire(EventBusModel(
          event: EventBusConst.eventSocketFailed, data: ConnectionErrorCode.timeoutNotConnected));
    });
  }

  void _onLinkUp() {
    _giveUpTimer?.cancel();
    _reconnectStartedAt = null;
    _lastRx = DateTime.now();
    _probeSentAt = null;
    state.value = LinkState.connected;
    Socket.instance.flushQueue();
    if (_inForeground) _startHeartbeat();
  }

  // ---------- بررسی سلامت ----------

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer =
        Timer.periodic(const Duration(seconds: SocketConstants.heartbeatIntervalSeconds), (_) {
      _heartbeatTick();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _probeSentAt = null;
  }

  void _heartbeatTick() {
    if (!_inForeground || !Socket.instance.isConnected()) return;
    final idle = DateTime.now().difference(_lastRx).inSeconds;
    if (idle >= SocketConstants.heartbeatIntervalSeconds) _sendProbe();
  }

  void _sendProbe() {
    if (_probeSentAt != null) return;
    _probeSentAt = DateTime.now();
    final sentAt = _probeSentAt;
    // پنل به این درخواست با اطلاعات آی‌پی جواب می‌دهد؛ جواب فقط نشانه‌ی زنده بودن است
    if (!Socket.instance.sendProbe(SocketConstants.requestIp)) return;

    Timer(const Duration(milliseconds: SocketConstants.heartbeatTimeoutMs), () {
      if (_probeSentAt == sentAt && _lastRx.isBefore(sentAt!)) {
        _logger('_sendProbe', 'no answer -> connection is dead');
        _probeSentAt = null;
        Socket.instance.disconnect();
        onSocketLost(ConnectionErrorCode.timeoutNotReceivedData);
      }
    });
  }

  void _logger(String key, String value) {
    doLogGlobal('connection_keeper', key, value);
  }
}
