import 'dart:async';

import 'package:bms/core/eventbus/event_bus_const.dart';
import 'package:bms/core/eventbus/event_bus_model.dart';
import 'package:bms/core/utils/constants.dart';
import 'package:bms/core/utils/globals.dart';
import 'package:bms/core/utils/util.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/result.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/new_connection_wraper/new_location_data_model.dart';
import 'package:bms/data/repositories/location_repository.dart';
import 'package:bms/domain/usecases/update_devices/update_devices_usecase_impl.dart';
import 'package:bms/presentation/logic/base_logic.dart';
import 'package:bms/presentation/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../../core/di/app_binding.dart';
import '../../data/data_sources/local_data_sources/database/model/location.dart';
import '../../data/data_sources/remote_data_sources/socket/connection_requests/connection_requests_impl.dart';
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
  }

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
      if (!status) {
        Utils.snackError(data);
      } else {
        Utils.snackSuccess('مودم تنظیم شد. $data');
      }
      mSetModemIpLoading = false;
      update();
    });
  }

  setModemConfig() {
    mSetModemIpLoading = true;
    update();

    _storeModemData();

    sendMessageToSocket(
        '#AT+CWJAP="${modemNameController.text}","${modemPasswordController.text}"#');

    _logger('setModemConfig - send ',
        ' #AT+CWJAP="${modemNameController.text}","${modemPasswordController.text}"#');
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
      Utils.toast('در حال اتصال...', Toast.LENGTH_LONG);
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
      Utils.snackError('دستگاه قبلا ایجاد شده است.');
    } else {
      Utils.snackError('.پاسخی دریافت نشد، لطفا دوباره تلاش کنید.');
      Utils.toast('Error: $reason', Toast.LENGTH_LONG);
    }
  }

  bool _connectionValidation() {
    if (locationNameController.text.isEmpty) {
      Get.snackbar('خطا', 'ورود نام مکان ضروری است');
      return false;
    }
    return true;
  }

  setStaticIpConfig() {
    locationToEdit!.staticIp = staticIpController.text;
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
    if (_isNamePasswordValid()) {
      _storeWifiData();
      sendMessageToSocket(
          '*AT+CWSAP="${wifiNameController.text}","${wifiPasswordController.text}",1,4*');
    } else {
      showValidationError();
    }
  }

  bool _isNamePasswordValid() {
    return wifiNameController.text.length > Constants.minimumBMSWifiNameCharacter &&
        wifiPasswordController.text.length == Constants.exactBMSWifiPasswordCharacter;
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

  void showValidationError() {
    Utils.snackError('تعداد کارکتر مجاز نام wifi باید بیشتر از '
        '${Constants.minimumBMSWifiNameCharacter} باشد \n و تعداد کاراکتر پسورد باید '
        '${Constants.exactBMSWifiPasswordCharacter} کاراکتر باشد.');
  }
}
