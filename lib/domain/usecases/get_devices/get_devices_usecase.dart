import '../../../data/data_sources/local_data_sources/database/model/device.dart';
import '../../../data/enums/floor_code.dart';
import '../../../data/enums/headline_code.dart';

abstract class GetDeviceUseCase {
  Future<List<Device>> getDevicesMuteHidden(int locationId,
      {bool wholeFloor,
        required FloorCode floor,
        required String placeCode,
        required HeadlineCode headline});
  Future<List<Device>> getDevices(int locationId,
      {bool wholeFloor,
      required FloorCode floor,
      required String placeCode,
      required HeadlineCode headline});

  Future<List<Device>> getDevicesByLocation({required int locationId});

  Future<List<Device>> getBurglarAlarmDevices(int locationId);
}
