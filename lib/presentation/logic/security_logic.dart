import 'dart:async';

import 'package:bms/core/utils/communication_constants.dart';
import 'package:bms/presentation/logic/base_logic.dart';
import 'package:get/get.dart';

import '../../core/eventbus/event_bus_const.dart';
import '../../core/eventbus/event_bus_model.dart';
import '../../core/utils/globals.dart';
import '../../data/data_sources/local_data_sources/database/app_database.dart';
import '../../data/data_sources/local_data_sources/database/model/device.dart';
import '../../domain/usecases/get_devices/get_devices_usecase_impl.dart';
import '../../domain/usecases/update_devices/update_devices_usecase_impl.dart';

class SecurityLogic extends BaseLogic {
  List<Device> zoneList = [];
  late int currentLocationId;
 StreamSubscription<EventBusModel>? _mSubscription;
   

  @override
  void onInit() async {
    await _initDevices();
    _listenEventBus();

    super.onInit();
  }

  _initDevices() async {
    currentLocationId = (await Get
        .find<AppDatabase>()
        .locationDao
        .all()).first.id!;
    zoneList = await GetDeviceUseCaseImpl().getBurglarAlarmDevices(currentLocationId);

    update();
  }

  void _listenEventBus() {
    _mSubscription = eventBus.on<EventBusModel>().listen((event) {
      switch (event.event) {
        case EventBusConst.eventNewBurglarAlarmData:
          _onEventNewBurglarAlarmDataHappened(event);
          break;
      }
    });
  }

  /// Samples that we expect : '@X1Z1on*Z2of*Z3on or '@X1Z1on'
  _onEventNewBurglarAlarmDataHappened(EventBusModel event) async {
    await UpdateDeviceUseCaseImpl().updateBurglarAlarm(currentLocationId, event.data as String);
    _initDevices();
  }

  requestBurglarAlarmStatus() {
    _logger('requestBurglarAlarmStatus', 'Method called. zoneList.length: ${zoneList.length}');
    sendMessageToSocket(SocketConstants.requestBurglarAlarms);
  }

  void _logger(String key, String value) {
    doLog('security_logic. H:$hashCode', key, value);
  }

  /// Sample Command &X1Z2
  changeDeviceValue(Device device) {
    var command = '${SocketConstants.command}${device.headline}${device.code}';
    sendMessageToSocket(command);
  }

  @override
  void onClose() {
    _logger('onClose', 'method called.');
    _mSubscription?.cancel(); // Cancel the subscription
    super.onClose();
  }
}
