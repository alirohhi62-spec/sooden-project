import 'package:bms/domain/extract_data/extract_data_usecase_impl.dart';
import 'package:get/get.dart';

import '../../../../../../../core/utils/communication_constants.dart';
import '../../../../../../../core/utils/globals.dart';
import '../../../../../../../core/utils/util.dart';
import '../../../../../../../domain/extract_data/extract_data_usecase.dart';
import '../../../../../../../domain/usecases/update_devices/update_devices_usecase_impl.dart';
import '../../../../../../model/parser_data_holder.dart';
import '../../../../../../repositories/location_repository.dart';
import '../../../../../local_data_sources/database/model/location.dart';
import '../../result.dart';
import '../connection_manager/connection_manager_data_model.dart';
import 'manage_global_scenario.dart';
import 'manage_new_locattion_data.dart';

class FakeNewLocationDataImpl extends MangeNewLocationData {
  late final Function(Result) _mResultCallback;
  String? mDeviceGottenConfig = '';
  late ConnectionManagerDataModel _mDataModel;

  late final LocationRepository _locationRepository = Get.find<LocationRepository>();
  late final UpdateDeviceUseCaseImpl _mUpdateDeviceUseCase = UpdateDeviceUseCaseImpl();

  FakeNewLocationDataImpl(this._mResultCallback);

  @override
  Future<void> startWorking(ConnectionManagerDataModel dataModel) async {
    _logger('_doTestWithoutPanel', 'Init mock data');
    _mDataModel = dataModel;

    var referenceLocation = await _insertMockLocation();
    _mDataModel.referenceLocation = referenceLocation;
    mDeviceGottenConfig = currentMockConfig;
    _startParsingFloorsData();
  }

  _doInsertLocation(Location loc) async {
    int locationId = await _locationRepository.insertIfNotExistForTestData(loc);
    await _locationRepository.updateSelectedLocation(locationId);
    var location = await _locationRepository.getLocation(id: locationId);
    return location;
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

  _insertMockLocation() async {
    var loc = Location(
        name: _mDataModel.newLocationDataModel?.locationName,
        staticIp: _mDataModel.newLocationDataModel?.ipStatic,
        port: SocketConstants.port,
        mac: '45:54',
        panelWifiName: 'ZADDFFF',
        panelIpOnModem: '192',
    );

    return await _doInsertLocation(loc);
  }

  void _logger(String key, String value) {
    doLogGlobal('manage_new_locattion_data. H:$hashCode', key, value);
  }
}
