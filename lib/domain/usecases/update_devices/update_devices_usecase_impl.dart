import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:bms/data/repositories/location_repository.dart';
import 'package:bms/domain/usecases/get_devices/get_devices_usecase_impl.dart';
import 'package:get/get.dart';

import '../../../core/utils/globals.dart';
import '../../../data/data_sources/local_data_sources/database/model/location.dart';
import '../../../data/data_sources/local_data_sources/database/model/place.dart';
import '../../../data/enums/floor_code.dart';
import '../../../data/enums/headline_code.dart';
import '../../../data/repositories/device_repository.dart';
import 'update_devices_usecase.dart';

class UpdateDeviceUseCaseImpl implements UpdateDeviceUseCase {
  late final DeviceRepository _deviceRepository = Get.find<DeviceRepository>();
  late final LocationRepository _mLocationRepository = Get.find<LocationRepository>();

  @override
  renamePlace(Place place, String newName) {
    place.name = newName;

    _deviceRepository.updatePlace(place);
  }

  @override
  renameDevice(Device device, String newName) {
    device.name = newName;

    _deviceRepository.updateDevice(device);
  }

  @override
  Future<void> changeDeviceValue(Device device, String newValue) {
    device.value = newValue;

    return _deviceRepository.updateDevice(device);
  }

  @override
  insertPlaceList(List<Place> places) => _deviceRepository.insertPlaces(places);

  @override
  insertDeviceList(List<Device> devices) async {
    await _deviceRepository.insertList(devices);
  }

  @override
  Future<void> changeDeviceStatuses(String statusAddress, String status) async {
    Iterable<Match> floorMatchesRegex = RegExp(r'T\d*').allMatches(statusAddress);

    String floor = floorMatchesRegex.first.group(0)!;
    String place2 = RegExp(r'.\d*')
        .allMatches(statusAddress.substring(statusAddress.indexOf(floor) + floor.length))
        .map((match) => match.group(0))
        .toList()[0]!;
    String headline = statusAddress.substring(statusAddress.indexOf(place2) + 1);

    Location? currLoc = await _mLocationRepository.getUserSelectedLocation();

    List<Device> devices = await GetDeviceUseCaseImpl().getDevices(currLoc!.id!,
        floor: FloorCode.get(floor), placeCode: place2, headline: HeadlineCode.get(headline));

    for (int i = 0; i < devices.length; i++) {
      await changeDeviceValue(devices[i], status[i]);
    }
  }

  /// Samples that we expect : '@X1Z1on*Z2of*Z3on or '@X1Z1on'
  updateBurglarAlarm(int locationId, String commandString) async {
    _logger('updateBurglarAlarm', 'commandString: $commandString');

    var deviceList =
        RegExp(r'Z\d+').allMatches(commandString).map((match) => match.group(0)).toList();
    var valueList =
        RegExp(r'[a-z]+').allMatches(commandString).map((match) => match.group(0)).toList();

    for (int i = 0; i < deviceList.length; i++) {
      await _deviceRepository.updateBurglarAlarmDevices(locationId, deviceList[i]!, valueList[i]!);
    }
  }

  void _logger(String key, String value) {
    doLogGlobal('update_devices_usecase_impl. H:$hashCode', key, value);
  }
}
