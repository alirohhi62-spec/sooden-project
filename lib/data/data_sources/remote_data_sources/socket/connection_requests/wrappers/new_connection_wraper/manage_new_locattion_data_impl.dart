import 'package:bms/domain/extract_data/extract_data_usecase_impl.dart';
import 'package:get/get.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../../../../../../core/utils/globals.dart';
import '../../../../../../../core/utils/util.dart';
import '../../../../../../../domain/extract_data/extract_data_usecase.dart';
import '../../../../../../../domain/usecases/update_devices/update_devices_usecase_impl.dart';
import '../../../../../../enums/connection_error_code.dart';
import '../../../../../../model/parser_data_holder.dart';
import '../../../../../../repositories/location_repository.dart';
import '../../../../../local_data_sources/database/model/location.dart';
import '../../result.dart';
import '../connection_manager/connection_manager_data_model.dart';
import 'manage_global_scenario.dart';
import 'manage_new_locattion_data.dart';

class MangeNewLocationDataImpl extends MangeNewLocationData {
  late final Function(Result) _mResultCallback;
  String? mDeviceGottenConfig = '';
  late ConnectionManagerDataModel _mDataModel;

  late final LocationRepository _locationRepository = Get.find<LocationRepository>();
  late final UpdateDeviceUseCaseImpl _mUpdateDeviceUseCase = UpdateDeviceUseCaseImpl();

  MangeNewLocationDataImpl(this._mResultCallback);

  @override
  void startWorking(ConnectionManagerDataModel dataModel) async {
    _mDataModel = dataModel;

    await _collectConfig();
    if (checkLocationInsertedOrIsRepeatedLocation()) {
      await _collectFloorsData(dataModel.getFloorAsSingleString());
    } else {
      _mResultCallback.call(Result.failure(ConnectionErrorCode.repeatedLocation));
    }
  }
  checkLocationInsertedOrIsRepeatedLocation() {
    if (_mDataModel.referenceLocation == null) {
      return false; // IsRepeatedLocation
    } else {
      return true; // LocationInserted
    }
  }

  Future<void> _collectConfig() async {
    _logger('_collectConfig',
        'data:${_mDataModel.getIpConfig().toString()} port:${_mDataModel.portToConnect}');
    _mDataModel.referenceLocation = await _insertLocation(_mDataModel);
  }

  _insertLocation(ConnectionManagerDataModel dataModel) async {
    String? panelWifiName = await NetworkInfo().getWifiName();

    var loc = Location(
        name: _mDataModel.newLocationDataModel?.locationName,
        staticIp: _mDataModel.newLocationDataModel?.ipStatic,
        port: dataModel.portToConnect!,
        mac: dataModel.getIpConfig().macAddress,
        panelWifiName: panelWifiName?.substring(1, panelWifiName.length - 1),
        panelIpOnModem: dataModel.getIpConfig().ipPanelOnModem,
        modemName: dataModel.getIpConfig().modemWifiName);
    return await _doInsertLocation(loc);
  }

  _doInsertLocation(Location loc) async {
    int locationId = await _locationRepository.insertIfNotExist(loc);
    await _locationRepository.updateSelectedLocation(locationId);
    var location = await _locationRepository.getLocation(id: locationId);
    return location;
  }

  _collectFloorsData(String data) async {
    _logger('_collectFloorsData', 'data:$data');

    mDeviceGottenConfig = data;
    _startParsingFloorsData();
  }

  _startParsingFloorsData() {
    ExtractDataUsecase dataParserUsecase = ExtractDataUsecaseImpl();
    dataParserUsecase.startParsing(
        mDeviceGottenConfig, _mDataModel.referenceLocation!.id, _onParsedCallback);
  }

  _onParsedCallback(ParserDataHolder dataHolder) => {_saveData(dataHolder)};

  _saveData(ParserDataHolder dataHolder) async {
    _logger('DataHolder', 'Method called.');
    await _mUpdateDeviceUseCase.insertDeviceList(dataHolder.devices);
    await _mUpdateDeviceUseCase.insertPlaceList(dataHolder.places.toList());
    await ManageGlobalScenario().createGeneralScenarios(_mDataModel.referenceLocation!.id);

    Utils.snackSuccess('new_location_saved'.tr);
    _mResultCallback.call(Result.success(_mDataModel));
  }

  void _logger(String key, String value) {
    doLogGlobal('manage_new_locattion_data. H:$hashCode', key, value);
  }
}
