import 'package:bms/data/data_sources/local_data_sources/database/app_database.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario_det.dart';
import 'package:bms/presentation/logic/base_logic.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../core/eventbus/event_bus_const.dart';
import '../../core/eventbus/event_bus_model.dart';
import '../../core/utils/communication_constants.dart';
import '../../core/utils/globals.dart';
import '../../core/utils/util.dart';
import '../../data/enums/floor_code.dart';
import '../../data/enums/headline_code.dart';
import '../../domain/usecases/get_devices/get_devices_usecase_impl.dart';

class NewPlaceScenariosLogic extends BaseLogic {
  late Place place;
  late FloorCode floor;
  late int currentLocationId;
  late GetDeviceUseCaseImpl _mDeviceUseCase;
  TextEditingController scenarioNameController = TextEditingController();
  final isScenarioForFloor = false.obs;
  Scenario? currentScenario;

  List<Device> devices = [];

  NewPlaceScenariosLogic(
      {required this.place, required this.floor, required this.currentLocationId});

  @override
  void onInit() {
    _initVariable();
    _initLights();
    super.onInit();
  }

  _initVariable() {
    _mDeviceUseCase = GetDeviceUseCaseImpl();
  }

  _initLights() async {
    _logger('_initLights', 'wholeFloor: ${isScenarioForFloor.value}');

    devices = await _mDeviceUseCase.getDevices(
      currentLocationId,
      wholeFloor: isScenarioForFloor.value,
      floor: floor,
      placeCode: place.code!,
      headline: HeadlineCode.light,
    );
    devices.addAll(await _mDeviceUseCase.getDevices(
      currentLocationId,
      wholeFloor: isScenarioForFloor.value,
      floor: floor,
      placeCode: place.code!,
      headline: HeadlineCode.curtain,
    ));
    update();
  }

  onScenarioForFloorChanged(bool newValue) {
    isScenarioForFloor.value = newValue;
    _initLights();
  }

  changeValue(int index, String newValue) {
    devices[index].value = newValue;

    update();
  }

  void createScenario() async {
    if (_validation() == false) return;

    var scenarioId = await _addToScenario();
    _logger('createScenario', 'scenarioId: $scenarioId');
    _addToScenarioDetails(scenarioId);
    _emitEventCreatedScenario();

    Get.back();

    Utils.snackSuccess('سناریو ایجاد شد.');
  }

  bool _validation() {
    if (scenarioNameController.text.isEmpty) {
      Get.snackbar('خطا', 'ورود نام  ضروری است');
      return false;
    }

    return true;
  }

  Future<int> _addToScenario() async {
    var model = Scenario(
      locationId: currentLocationId,
      floor: floor.value,
      place: isScenarioForFloor.value ? null : place.code,
      name: scenarioNameController.text,
    );
    return await Get.find<AppDatabase>().scenarioDao.insert(model);
  }

  void _addToScenarioDetails(int scenarioId) async {
    List<ScenarioDet> dataList = [];
    for (var index = 0; index < devices.length; index++) {
      String status = devices[index].value == null ? 'false' : devices[index].value.toString();
      var model = ScenarioDet(
          scenarioId: scenarioId,
          deviceId: devices[index].id,
          deviceName: devices[index].name,
          value: status);
      dataList.add(model);
    }
    _logger('createScenario', 'ScenarioDet length: ${dataList.length}');
    return await Get.find<AppDatabase>().scenarioDetDao.insertList(dataList);
  }

  void _emitEventCreatedScenario() {
    eventBus.fire(EventBusModel(event: EventBusConst.eventUpdatedScenario));
  }

  bool isLight(Device device) {
    return device.headline == HeadlineCode.light.value;
  }

  void _logger(String key, String value) {
    doLog('new_place_scenarios_logic. H:$hashCode', key, value);
  }

  getValueCurtain(Device device) {
    _logger('getValueCurtain', 'value: ${device.value}');

    device.value ??= SocketConstants.curtainStop;
    return device.value;
  }

  bool isHiddenLight(Device device) {
    return device.code == SocketConstants.hiddenDevice;
  }
}
