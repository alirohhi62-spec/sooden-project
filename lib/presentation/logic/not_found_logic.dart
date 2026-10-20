import 'dart:async';

import 'package:bms/core/di/app_binding.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/socket.dart';
import 'package:bms/presentation/logic/base_logic.dart';
import 'package:get/get.dart';

import '../../core/eventbus/event_bus_const.dart';
import '../../core/eventbus/event_bus_model.dart';
import '../../core/utils/globals.dart';
import '../../data/data_sources/remote_data_sources/socket/connection_requests/connection_requests_impl.dart';
import '../screens/splash/splash_screen.dart';

class NotFoundLogic extends BaseLogic {
  StreamSubscription<EventBusModel>? _mSubscription;

  @override
  onReady() async {
    super.onReady();
    _logger('onReady', 'Method called');
    _destroyConnection();
    _listenEventBus();
  }

  void _destroyConnection(){
    _logger('_disconnectSocket', 'Method called');
    ConnectionRequestsImpl.instance.destroyConnections();
  }

  void _listenEventBus() {
    _mSubscription = eventBus.on<EventBusModel>().listen((event) {
      _logger('_listenEventBus', 'event: ${event.event}');

      switch (event.event) {
        case EventBusConst.eventSocketReconnect:
          _onEventSocketReconnectHappened();
          break;
      }
    });
  }

  void _onEventSocketReconnectHappened() {
    _logger('_onEventSocketReconnectHappened', 'Method called');

    Get.offAll(() => SplashScreen(), binding: AppBindings());
  }

  void onTryAgain() async {
    Get.offAll(() => SplashScreen(), binding: AppBindings());
  }

  @override
  void onClose() {
    _logger('onClose', 'method called.');
    _mSubscription?.cancel(); // Cancel the subscription
    super.onClose();
  }

  void _logger(String key, String value) {
    doLog('not_found_logic. H:$hashCode', key, value);
  }
}
