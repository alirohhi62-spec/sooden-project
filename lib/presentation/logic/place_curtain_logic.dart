import 'dart:async';

import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:bms/domain/usecases/get_devices/get_devices_usecase_impl.dart';
import 'package:bms/presentation/logic/base_logic.dart';
import 'package:get/get.dart';

import '../../core/eventbus/event_bus_const.dart';
import '../../core/eventbus/event_bus_model.dart';
import '../../core/utils/communication_constants.dart';
import '../../core/utils/globals.dart';
import '../../data/enums/floor_code.dart';
import '../../data/enums/headline_code.dart';
import '../../domain/usecases/update_curtain/update_curtain_usecase_impl.dart';

class PlaceCurtainLogic extends BaseLogic {
  late FloorCode floor;
  late Place place;
  late String title;
  List<Device> devices = [];
 StreamSubscription<EventBusModel>? _mSubscription;

  PlaceCurtainLogic({required this.floor, required this.place});

  @override
  void onInit() {
    title = '${'shutters'.tr} ${place.getName()}';
    _listenEventBus();
    _initCurtains();
    _requestCurtainStatus();
    super.onInit();
  }

  _initCurtains() async {
    devices = await GetDeviceUseCaseImpl().getDevicesMuteHidden(
      place.locationId!,
      floor: floor,
      placeCode: place.code!,
      headline: HeadlineCode.curtain,
    );

    update();
  }

  void _listenEventBus() {
    _mSubscription =  eventBus.on<EventBusModel>().listen((event) {
      switch (event.event) {
        case EventBusConst.eventNewCurtainData:
          _onEventNewCurtainDataHappened(event);
          break;

        // بعد از اتصال دوباره، وضعیت پرده‌ها دوباره از پنل گرفته شود
        case EventBusConst.eventSocketReconnect:
          _requestCurtainStatus();
          break;
      }
    });
  }

  /// Samples that we expect : '@T1A1Vp1-9S/q1-0S/p2-4C/q2-9S/p3-7O or '@TA1Vp1-9C'
  _onEventNewCurtainDataHappened(EventBusModel event) async {
    await UpdateCurtainUseCaseImpl().update(place, event.data as String);

    _initCurtains();
  }

  /// Sample request @TA1V
  _requestCurtainStatus() {
    _logger('_requestCurtainStatus', 'Method called.');
    sendMessageToSocket(
        '${SocketConstants.request}${floor.value}${place.code}${HeadlineCode.curtain.value}');
  }

  /// Sample commands Open: &TA1Vp1O, Close: &TA1Vp1C, Stop: &TA1Vp1S
  changeDeviceValue(Device device, String newValue) {
    _logger('changeDeviceValue', ' newValue: $newValue.');

    _ensureStopping(device, newValue);
    var command = makeCommand(device, newValue);

    sendMessageToSocket(command);
  }


  void _ensureStopping(Device device, String newValue) {
    _logger('_ensureStopping', ' newValue: $newValue.');

    if (getValue(device) != SocketConstants.curtainStop &&
        newValue != SocketConstants.curtainStop) {

      var command = makeCommand(device, SocketConstants.curtainStop);
      _logger('_ensureStopping', 'Need to stop first, command: $command.');

      sendMessageToSocket(command);
    }
  }

  String makeCommand(Device device, String newValue) {
    return '${SocketConstants.command}${floor.value}${place.code}'
        '${HeadlineCode.curtain.value}${device.code}$newValue';
  }

  String getValue(Device device) {
    return device.value ?? SocketConstants.curtainStop;
  }

  @override
  void onClose() {
    _logger('onClose', 'method called.');
    _mSubscription?.cancel(); // Cancel the subscription
    super.onClose();
  }

  void _logger(String key, String value) {
    doLog('place_curtain_logic. H:$hashCode', key, value);
  }
}
