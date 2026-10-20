import 'dart:async';

import 'package:bms/core/utils/globals.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:bms/presentation/logic/base_logic.dart';
import 'package:get/get.dart';

import '../../core/eventbus/event_bus_const.dart';
import '../../core/eventbus/event_bus_model.dart';
import '../../core/utils/communication_constants.dart';
import '../../data/enums/floor_code.dart';
import '../../data/enums/headline_code.dart';
import '../../domain/usecases/change_light_status/change_light_status_usecase_impl.dart';
import '../../domain/usecases/get_devices/get_devices_usecase_impl.dart';

class PlaceLightsLogic extends BaseLogic {
  late final ChangeLightStatusUsecaseImpl _mChangeLightStatus = ChangeLightStatusUsecaseImpl();
  late FloorCode floor;
  late Place place;
  late String title;
  List<Device> devices = [];
  StreamSubscription<EventBusModel>? _mSubscription;

  PlaceLightsLogic({required this.floor, required this.place});

  @override
  void onInit() {
    title = '${'light'.tr} ${place.getName()}';

    _requestLightsStatus();

    Future.delayed(const Duration(milliseconds: SocketConstants.placeLightsInitDelay),
            () => _initLights());

    _listenEventBus();

    super.onInit();
  }

  void _listenEventBus() {
    _mSubscription = eventBus.on<EventBusModel>().listen((event) {
      switch (event.event) {
        case EventBusConst.eventUpdatedDevice:
          _onEventUpdatedDeviceHappened(event);
          break;

        // بعد از اتصال دوباره، وضعیت چراغ‌ها دوباره از پنل گرفته شود
        case EventBusConst.eventSocketReconnect:
          _requestLightsStatus();
          break;
      }
    });
  }

  void _onEventUpdatedDeviceHappened(EventBusModel event) {
    _initLights();
  }

  _requestLightsStatus() {
    sendMessageToSocket(
        '${SocketConstants.request}${floor.value}${place.code}${HeadlineCode.light.value}');
  }

  _initLights() async {
    devices = await GetDeviceUseCaseImpl().getDevicesMuteHidden(
      place.locationId!,
      floor: floor,
      placeCode: place.code!,
      headline: HeadlineCode.light,
    );

    update();
  }

  changeLightDevicesValue(Device device) {
    _mChangeLightStatus.requestChangeLight(device, place);
    update();
  }

  @override
  void onClose() {
    _logger('onClose', 'method called.');
    _mSubscription?.cancel(); // Cancel the subscription
    super.onClose();
  }

  void _logger(String key, String value) {
    doLog('place_lights_logic. H:$hashCode', key, value);
  }
}
