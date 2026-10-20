import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:bms/data/enums/floor_code.dart';
import 'package:get/get.dart';

import '../../../core/utils/globals.dart';
import '../../../data/enums/headline_code.dart';
import '../../../data/repositories/device_repository.dart';
import 'get_devices_usecase.dart';

class GetDeviceUseCaseImpl implements GetDeviceUseCase {
  late final DeviceRepository _deviceRepository = Get.find<DeviceRepository>();

  @override
  Future<List<Device>> getDevicesMuteHidden(int locationId,
      {bool? wholeFloor,
      required FloorCode floor,
      required String placeCode,
      required HeadlineCode headline}) {
    return _deviceRepository.getDevicesMuteHidden(locationId,floor: floor, placeCode: placeCode, headline: headline);
  }

  @override
  Future<List<Device>> getDevices(int locationId,
      {bool? wholeFloor,
      required FloorCode floor,
      required String placeCode,
      required HeadlineCode headline}) {
    if (wholeFloor != null && wholeFloor) {
      _logger('getDevices', 'wholeFloor: $wholeFloor');
      return _deviceRepository.getDevicesOfFloor(locationId, floor: floor, headline: headline);
    } else {
      return _deviceRepository.getDevices(locationId,floor: floor, placeCode: placeCode, headline: headline);
    }
  }

  @override
  Future<List<Device>> getDevicesByLocation({required int locationId}) {
    return _deviceRepository.getDevicesByLocation(locationId: locationId);
  }

  @override
  Future<List<Device>> getBurglarAlarmDevices(int locationId) {
    return _deviceRepository.getBurglarAlarmDevices(locationId);
  }

  void _logger(String key, String value) {
    doLogGlobal('get_devices_usecase_impl. H:$hashCode', key, value);
  }
}
