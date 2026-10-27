import 'dart:async';
import 'dart:convert';

import 'package:bms/core/eventbus/event_bus_const.dart';
import 'package:bms/core/eventbus/event_bus_model.dart';
import 'package:bms/core/utils/globals.dart';
import 'package:bms/core/utils/util.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/result.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/new_connection_wraper/new_location_data_model.dart';
import 'package:bms/data/repositories/location_repository.dart';
import 'package:bms/domain/usecases/update_devices/update_devices_usecase_impl.dart';
import 'package:bms/presentation/logic/base_logic.dart';
import 'package:bms/presentation/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/di/app_binding.dart';
import '../../data/data_sources/local_data_sources/database/model/location.dart';
import '../../data/data_sources/remote_data_sources/socket/connection_requests/connection_requests_impl.dart';
import '../../data/data_sources/remote_data_sources/socket/connection_requests/wrappers/connection_wraper/connection_wraper_impl.dart';
import '../../data/data_sources/remote_data_sources/socket/connection_requests/wrappers/connection_manager/connection_manager_data_model.dart';
import '../../data/enums/connection_error_code.dart';
import '../../domain/usecases/set_modem/set_modem_usecase_impl.dart';

class NewLocationLogic extends BaseLogic {
  late Location? locationToEdit;
  var isEditMode = false;
  bool isLoading = false;

  TextEditingController locationNameController = TextEditingController();

  TextEditingController wifiNameController = TextEditingController();
  TextEditingController wifiPasswordController = TextEditingController();

  TextEditingController macAddressController = TextEditingController();
  TextEditingController modemNameController = TextEditingController();
  TextEditingController modemPasswordController = TextEditingController();
  TextEditingController panelIpOnModemController = TextEditingController();

  TextEditingController staticIpController = TextEditingController();
  late UpdateDeviceUseCaseImpl updateDeviceUseCase;
  bool mSetModemIpLoading = false;

  /// خطای اتصال به پنل (کارت قرمز بالای صفحه)؛ null = خطایی نیست
  String? connError;
  /// نتیجه‌ی ثبت وای‌فای پنل و اتصال پنل به مودم (زیر همان کارت)
  String? wifiMsg, modemMsg;
  bool wifiOk = false, modemOk = false;
  /// وای‌فای فعلی گوشی ('' = وای‌فای نیست یا اجازه‌ی موقعیت داده نشده)
  String phoneWifi = '';
  bool showMore = false;
  late final LocationRepository _locationRepository = Get.find<LocationRepository>();
  StreamSubscription<EventBusModel>? _mSubscription;
  StreamSubscription<Result>? _mConnectionSubscription;

  NewLocationLogic(this.locationToEdit) {
    isEditMode = locationToEdit != null;

    _initFields(locationToEdit);
  }

  @override
  onInit() {
    _initVariable();
    _listenEventBus();

    super.onInit();
  }

  void _initVariable() {
    updateDeviceUseCase = UpdateDeviceUseCaseImpl();
    refreshPhoneWifi();
  }

  Future<void> refreshPhoneWifi() async {
    phoneWifi = await ConnectionWrapperImpl.currentWifi();
    update();
  }

  /// گوشی به وای‌فای خود پنل وصل است؟ (اسم پیش‌فرض sooden-... یا اسم ذخیره‌شده‌ی این مکان)
  bool get onPanelWifi =>
      phoneWifi.isNotEmpty &&
      (phoneWifi.toLowerCase().startsWith('sooden') || (locationToEdit?.panelWifiName ?? '') == phoneWifi);

  static const _ch = MethodChannel('sooden/sms');
  Future<void> openWifiSettings() async {
    try {
      await _ch.invokeMethod('wifiSettings');
    } catch (_) {}
  }

  /// " , \ در فرمان AT باید با \ بیایند (اسم و رمز با هر حرفی)
  static String atEsc(String v) => v.replaceAllMapped(RegExp(r'[\\",]'), (m) => '\\${m[0]}');
  static int bytes(String v) => utf8.encode(v).length;

  /// اسم وای‌فای پنل: هر حرفی، ۱ تا ۳۲ بایت (حرف فارسی ۲ بایت). رمز: خالی (بی‌رمز) یا ۸ تا ۴۰ حرف. null = درست
  static String? checkPanelWifi(String name, String pw) {
    if (name.trim().isEmpty) return 'اسم وای‌فای را بنویسید.';
    if (bytes(name) > 32) return 'اسم وای‌فای طولانی است: حداکثر ۳۲ حرف انگلیسی (یا حدود ۱۶ حرف فارسی).';
    if (pw.isNotEmpty && pw.length < 8) return 'رمز باید خالی (وای‌فای بدون رمز) یا دست‌کم ۸ حرف باشد.';
    if (bytes(pw) > 40) return 'رمز حداکثر ۴۰ حرف انگلیسی است.';
    return null;
  }

  static String apCommand(String name, String pw) =>
      '*AT+CWSAP="${atEsc(name)}","${atEsc(pw)}",1,${pw.isEmpty ? 0 : 4}*';
  static String joinCommand(String name, String pw) => '#AT+CWJAP="${atEsc(name)}","${atEsc(pw)}"#';

  void _listenEventBus() {
    _mSubscription = eventBus.on<EventBusModel>().listen((event) {
      switch (event.event) {
        case EventBusConst.eventNewFeedbackSetModemData:
          _onEventSetModemHappened(event);
          break;
      }
    });
  }

  /// Sample :
  /// @M_S=IP STATIC
  /// @M_S=Repeat
  /// @M_S=Error
  void _onEventSetModemHappened(EventBusModel event) {
    SetModemUsecaseImpl().setModemData(locationToEdit!, event.data!, (bool status, String data) {
      modemOk = status;
      modemMsg = status ? 'پنل به مودم وصل شد.' : data;
      if (status) panelIpOnModemController.text = locationToEdit?.panelIpOnModem ?? panelIpOnModemController.text;
      mSetModemIpLoading = false;
      update();
    });
  }

  setModemConfig() {
    if (modemNameController.text.trim().isEmpty) {
      modemOk = false;
      modemMsg = 'اسم وای‌فای مودم منزل را بنویسید.';
      update();
      return;
    }
    if (bytes(modemNameController.text) > 32 || bytes(modemPasswordController.text) > 64) {
      modemOk = false;
      modemMsg = 'اسم مودم حداکثر ۳۲ و رمز آن حداکثر ۶۴ حرف انگلیسی است.';
      update();
      return;
    }
    mSetModemIpLoading = true;
    modemMsg = null;
    update();

    _storeModemData();

    final cmd = joinCommand(modemNameController.text, modemPasswordController.text);
    sendMessageToSocket(cmd);
    _logger('setModemConfig - send ', cmd);
    // پنل تا ۲۰ ثانیه برای وصل شدن به مودم وقت دارد
    Future.delayed(const Duration(seconds: 30), () {
      if (mSetModemIpLoading) {
        mSetModemIpLoading = false;
        modemOk = false;
        modemMsg = 'پاسخی از پنل نیامد. گوشی هنوز به وای‌فای پنل وصل است؟ دوباره «تست اتصال» را بزنید.';
        update();
      }
    });
  }

  _storeModemData() {
    locationToEdit!.modemName = modemNameController.text;
    locationToEdit!.modemPassword = modemPasswordController.text;
    _locationRepository.updateLocation(locationToEdit!);
  }

  _initFields(Location? mLocation) {
    if (mLocation != null) {
      locationToEdit = mLocation;
    }

    if (locationToEdit != null) {
      locationNameController.text = locationToEdit!.name ?? '';
      wifiNameController.text = locationToEdit!.panelWifiName??'';
      wifiPasswordController.text = locationToEdit!.panelWifiPassword ?? '';

      macAddressController.text = locationToEdit!.mac!;
      modemNameController.text = locationToEdit!.modemName ?? '';
      modemPasswordController.text = locationToEdit!.modemPassword ?? '';
      panelIpOnModemController.text = locationToEdit!.panelIpOnModem ?? '';

      staticIpController.text = locationToEdit!.staticIp ?? '';

      update();
    }
  }

  checkConnection() async {
    if (_connectionValidation() == false) return;
    connError = null;
    await refreshPhoneWifi();

    _mConnectionSubscription?.cancel();

    var subject = ConnectionRequestsImpl.instance.newLocationRequest(
        NewLocationDataModel(locationNameController.text, staticIpController.text));
    _mConnectionSubscription = subject.listen((result) {
      onConnectionResult(result);
    });
  }

  void onConnectionResult(Result result) {
    if (result.isLoading) {
      isLoading = true;
      update();
    } else if (result.isSuccess) {
      isLoading = false;

      _onConnectedCallback(result.successValue);
    } else {
      isLoading = false;

      _onFailedCallback(result.failureValue);
      update();
    }
  }

  _onConnectedCallback(ConnectionManagerDataModel? dataModel) {
    _logger('_onConnectedCallback', 'dataModel : ${dataModel!.referenceLocation!.name}');

    _initFields(dataModel!.referenceLocation);
  }

  _onFailedCallback(ConnectionErrorCode? reason) {
    _logger('_onFailedCallback', 'reason : $reason');

    if (reason != null && reason == ConnectionErrorCode.repeatedLocation) {
      connError = 'این پنل قبلاً در یکی از مکان‌ها ذخیره شده است. از صفحه‌ی «مکان‌های من» همان مکان را انتخاب کنید.';
    } else {
      connError = 'پنل جواب نداد';
    }
  }

  bool _connectionValidation() {
    if (locationNameController.text.trim().isEmpty) {
      connError = 'اسم مکان را بنویسید (مثلاً منزل یا ویلا).';
      update();
      return false;
    }
    return true;
  }

  setStaticIpConfig() {
    locationToEdit!.staticIp = staticIpController.text.trim();
    _locationRepository.updateLocation(locationToEdit!);
  }

  bool visibleOtherFields() {
    return locationToEdit != null;
  }

  void goToMainClicked() {
    if (!isEditMode) {
      Get.offAll(() => SplashScreen(), binding: AppBindings());
    } else {
      Get.back();
    }
  }

  void onSetDeviceNamePassword() {
    final err = checkPanelWifi(wifiNameController.text, wifiPasswordController.text);
    if (err != null) {
      wifiOk = false;
      wifiMsg = err;
      update();
      return;
    }
    _storeWifiData();
    sendMessageToSocket(apCommand(wifiNameController.text, wifiPasswordController.text));
    wifiOk = true;
    wifiMsg = 'ثبت شد. پنل چند ثانیه بعد با اسم «${wifiNameController.text}» دیده می‌شود؛ '
        'گوشی را به همین وای‌فای وصل کنید${wifiPasswordController.text.isEmpty ? ' (بدون رمز).' : ' و رمز تازه را بزنید.'}';
    update();
  }

  void _storeWifiData() {
    locationToEdit!.panelWifiName = wifiNameController.text;
    locationToEdit!.panelWifiPassword = wifiPasswordController.text;
    _locationRepository.updateLocation(locationToEdit!);
  }

  @override
  void onClose() {
    _logger('onClose', 'method called.');
    locationNameController.dispose();
    _mSubscription?.cancel(); // Cancel the subscription
    _mConnectionSubscription?.cancel(); // Cancel the subscription
    super.onClose();
  }

  void _logger(String key, String value) {
    doLog('new_location_logic. H:$hashCode', key, value);
  }

}
