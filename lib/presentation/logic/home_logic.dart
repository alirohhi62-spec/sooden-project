import 'dart:async';

import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/utils/globals.dart';
import 'package:bms/core/values/colors.dart';
import 'package:bms/data/data_sources/local_data_sources/database/app_database.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:bms/data/enums/connection_error_code.dart';
import 'package:bms/data/repositories/device_repository.dart';
import 'package:bms/domain/usecases/get_scenario/get_scenario_usecase_impl.dart';
import 'package:bms/domain/usecases/get_weather/get_weather_usecase_impl.dart';
import 'package:bms/domain/usecases/run_scenario/run_scenario_usecase_impl.dart';
import 'package:bms/presentation/logic/base_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../../core/di/app_binding.dart';
import '../../core/eventbus/event_bus_const.dart';
import '../../core/eventbus/event_bus_model.dart';
import '../../core/utils/util.dart';
import '../../data/data_sources/local_data_sources/database/model/scenario.dart';
import '../../data/data_sources/remote_data_sources/socket/connection_requests/connection_requests_impl.dart';
import '../../data/data_sources/remote_data_sources/socket/connection_keeper.dart';
import '../../panel12/panel12_controller.dart';
import '../../sim12/sim12_start.dart';
import '../../data/data_sources/remote_data_sources/socket/connection_requests/result.dart';
import '../../data/data_sources/remote_data_sources/socket/connection_requests/wrappers/connection_manager/connection_manager_data_model.dart';
import '../../data/enums/floor_code.dart';
import '../../data/enums/headline_code.dart';
import '../../data/model/headline.dart';
import '../../domain/usecases/remove_scenario/remove_scenatio_impl.dart';
import '../../domain/usecases/update_devices/update_devices_usecase_impl.dart';
import '../../presentation/screens/notfound/not_found_screen.dart';

class HomeLogic extends BaseLogic {
  List<DropdownMenuItem> floorsWidget = [];
  late int currentLocationId;
  late FloorCode currentFloor = FloorCode.panelTak;
  late final DeviceRepository _mDeviceRepository = Get.find<DeviceRepository>();
  List<Place> places = [];

  late Place currentPlaceModel;
  bool hasElevator = false;
  final isSocketConnecting = false.obs;
  List<Headline> headlines = [];
  List<Scenario> localScenario = [];
  StreamSubscription<EventBusModel>? _mSubscription;
  StreamSubscription<Result>? _mConnectionSubscription;

  @override
  onInit() async {
    super.onInit();
    _logger('onInit 5', 'Method called');
  }

  @override
  onReady() async {
    super.onReady();
    _logger('onReady', 'Method called');
    enableGPS();
    _listenEventBus();
    await _initConnection();
  }

  Future<void> _initWithMockData() async {
    currentLocationId = (await Get.find<AppDatabase>().locationDao.all()).first.id!;
    await initDataView();
  }

  void _listenEventBus() {
    _mSubscription = eventBus.on<EventBusModel>().listen((event) {
      _logger('_listenEventBus', 'event: ${event.event}');

      switch (event.event) {
        case EventBusConst.eventUpdatedUserName:
          _onEventUpdatedUserNameHappened();
          break;

        case EventBusConst.eventUpdatedScenario:
          _onEventUpdatedScenarioHappened();
          break;

        case EventBusConst.eventSocketFailed:
          // go to not found
          goToNoFoundScreen(event.data as ConnectionErrorCode);
          break;
      }
    });
  }

  _onEventUpdatedUserNameHappened() {
    _logger('_onEventUpdatedUserNameHappened', "No Value");

    update();
  }

  _onEventUpdatedScenarioHappened() {
    _logger('_onEventCreatedScenarioHappened', "No Value");

    _initLocalScenario();
  }

  Future<void> _initConnection() async {
    _logger('_initConnection', 'Method called');

    if (testWithoutPanel) {
      await _initWithMockData();
      isSocketConnecting.value = false;
    } else {
      await _establishConnection();
    }
  }

  Future<void> _establishConnection() async {
    _logger('_establishConnection', 'Method called');

    _mConnectionSubscription?.cancel();
    var subject = ConnectionRequestsImpl.instance.multiConnectionRequest();
    _mConnectionSubscription = subject.listen((result) {
      onConnectionResult(result);
    });
  }

  void onConnectionResult(Result result) {
    final bool isReconnect = ConnectionKeeper.instance.hasSession;

    if (result.isLoading) {
      isSocketConnecting.value = true;
      // در اتصال دوباره، فقط نوار کوچک «در حال اتصال» نمایش داده می‌شود
      if (!isReconnect && !ConnectionKeeper.smsAccepted) Utils.toast('در حال اتصال...', Toast.LENGTH_LONG);
    } else if (result.isSuccess) {
      _onConnected(result.successValue);
    } else if (isReconnect) {
      // صفحه‌ی خطا فقط اگر اتصال تا ۲۰ ثانیه برقرار نشود (توسط نگهبان اتصال)
      ConnectionKeeper.instance.onFullReconnectFailed();
    } else {
      goToNoFoundScreen(result.failureValue);
    }
  }

  Future<void> _onConnected(ConnectionManagerDataModel dataModel) async {
    _logger('_onConnected', 'connectedLocation: ${dataModel.referenceLocation!.name}');

    final int newLocationId = dataModel.referenceLocation!.id!;
    final bool sameLocation =
        ConnectionKeeper.instance.hasSession && _dataViewReady && currentLocationId == newLocationId;

    currentLocationId = newLocationId;
    isSocketConnecting.value = false;
    ConnectionKeeper.instance.onSessionReady();
    Panel12Controller.instance.onSession();

    if (sameLocation) {
      // اتصال دوباره به همان مکان: صفحه دوباره ساخته نمی‌شود
      eventBus.fire(EventBusModel(event: EventBusConst.eventSocketReconnect));
      return;
    }
    await initDataView();
  }

  bool _dataViewReady = false;

  Future<void> initDataView() async {
    await _initFloors();
    if (!await _initPlaces()) return;
    await _initHeadlines();
    await _initLocalScenario();
    await checkHasElevator();
    _dataViewReady = true;
  }

  _initFloors() async {
    List<String> floors = await _mDeviceRepository.getFloors(currentLocationId);
    // قبلاً این لیست هیچ‌وقت پاک نمی‌شد و با هر اتصال دوباره طبقه‌ها تکراری می‌شدند
    floorsWidget.clear();
    if (floors.isEmpty) return;
    currentFloor = FloorCode.get(floors.first);

    if (floors.length > 1) {
      for (var floor in floors) {
        floorsWidget.add(DropdownMenuItem<FloorCode>(
            value: FloorCode.get(floor),
            child: Text(
              FloorCode.get(floor).title!,
            )));
      }
    }
  }

  changeFloor(floor) async {
    currentFloor = floor;

    // قبلاً بدون انتظار اجرا می‌شد و ممکن بود اطلاعات طبقه‌ی قبلی نمایش داده شود
    if (!await _initPlaces()) return;
    await checkHasElevator();
    await _initHeadlines();
    await _initLocalScenario();
  }

  /// false یعنی این طبقه مکانی ندارد
  Future<bool> _initPlaces() async {
    final list = await _mDeviceRepository.getPlaces(currentLocationId, floor: currentFloor.value);
    places = list;
    if (places.isEmpty) {
      update();
      return false;
    }
    currentPlaceModel = places.first;
    return true;
  }

  changePLace(Place place) {
    currentPlaceModel = place;

    _initHeadlines();
    _initLocalScenario();
  }

  _initHeadlines() async {
    headlines = await Get.find<AppDatabase>().deviceDao.getHeadLines(
          currentLocationId,
          currentFloor.value,
          currentPlaceModel.code!,
        );

    update();
  }

  headlineIcon(Headline headline) {
    switch (headline.code) {
      case HeadlineCode.light:
        return SvgPicture.asset(
          'assets/icons/light.svg',
          width: 36.0.dp,
          height: 36.0.dp,
          color: headline.active! ? AppColors.lightColor : AppColors.inactiveColor,
        );

      case HeadlineCode.temperature:
        return SvgPicture.asset(
          'assets/icons/temperature.svg',
          width: 36.0.dp,
          height: 36.0.dp,
          color: headline.active! ? AppColors.temperatureColor : AppColors.inactiveColor,
        );

      case HeadlineCode.curtain:
        return SvgPicture.asset(
          'assets/icons/curtain.svg',
          width: 36.0.dp,
          height: 36.0.dp,
          color: headline.active! ? AppColors.shuttersColor : AppColors.inactiveColor,
        );

      case HeadlineCode.scenarios:
        return SvgPicture.asset(
          'assets/icons/play.svg',
          width: 36.0.dp,
          height: 36.0.dp,
          color: headline.active! ? AppColors.scenariosColor : AppColors.inactiveColor,
        );
    }
  }

  _initLocalScenario() async {
    _logger(
        '_initLocalScenario',
        'currentLocationId : $currentLocationId'
            ' currentPlaceModelCode: ${currentPlaceModel.code!}'
            ' currentFloorValue: ${currentFloor.value}');
    var usecase = GetScenarioUseCaseImpl();
    localScenario = await usecase.getScenarioBothFloorAndPlace(
        currentLocationId, currentPlaceModel.code, currentFloor.value);
    update();
  }

  checkHasElevator() async {
    hasElevator = await _mDeviceRepository.hasElevator(
        locationId: currentLocationId, floor: currentFloor.value);
    update();
  }

  callElevator() {
    sendMessageToSocket('&${currentFloor.value}L');
    _logger("callElevator", 'command: &${currentFloor.value}L');
  }

  renamePlace(Place place, String newName) {
    UpdateDeviceUseCaseImpl().renamePlace(place, newName);

    update();
  }

  onScenarioClicked(Scenario scenario) async {
    final local = RunScenarioUseCaseImpl();
    local.runScenario(scenario);
  }

  removeScenario(Scenario scenario) async {
    RemoveScenarioUseCaseImpl().removeScenario(scenario);
  }

  Future<String> getWeather() async {
    return GetWeatherCaseImpl().getWeather();
  }

  bool _simAsked = false;

  void goToNoFoundScreen(ConnectionErrorCode errorCode) {
    // پنل سیمکارتی، اولین اتصال ناموفق: پرسیده می‌شود با سیمکارت ادامه دهد یا نه
    if (!ConnectionKeeper.instance.hasSession && !ConnectionKeeper.smsAccepted && Sim12Start.lastWasSim12()) {
      if (_simAsked) return;
      _simAsked = true;
      isSocketConnecting.value = false;
      Sim12Start.ask(onYes: () {
        ConnectionKeeper.smsAccepted = true;
        _retryWifiLater();
      }, onNo: () => Get.off(() => NotFoundScreen(errorCode: errorCode), binding: AppBindings()));
      return;
    }
    if (ConnectionKeeper.holding) {
      // پنل سیمکارتی با شماره‌ی تعریف‌شده: در صفحه می‌ماند (پیامکی) و ۱۰ ثانیه بعد دوباره وصل می‌شود
      isSocketConnecting.value = false;
      Future.delayed(const Duration(seconds: 10), () {
        if (!isClosed && ConnectionKeeper.instance.state.value != LinkState.connected) _establishConnection();
      });
      return;
    }
    // go to not found
    Get.off(() => NotFoundScreen(errorCode: errorCode), binding: AppBindings());
  }

  /// در حالت پیامکی: هر ۱۵ ثانیه وای‌فای دوباره امتحان می‌شود (وصل شد = خودکار وای‌فای)
  void _retryWifiLater() {
    Future.delayed(const Duration(seconds: 15), () {
      if (isClosed || ConnectionKeeper.instance.state.value == LinkState.connected) return;
      _establishConnection();
    });
  }

  @override
  void onClose() {
    _logger('onClose', 'method called.');
    _mSubscription?.cancel(); // Cancel the subscription
    _mConnectionSubscription?.cancel(); // Cancel the subscription
    super.onClose();
  }

  void _logger(String key, String value) {
    doLog('home_logic. H:$hashCode', key, value);
  }
}
