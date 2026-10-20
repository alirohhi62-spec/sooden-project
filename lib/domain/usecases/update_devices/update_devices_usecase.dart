import '../../../data/data_sources/local_data_sources/database/model/device.dart';
import '../../../data/data_sources/local_data_sources/database/model/place.dart';

abstract class UpdateDeviceUseCase {
  renamePlace(Place place, String newName) ;
  renameDevice(Device device, String newName);
  Future<void> changeDeviceValue(Device device, String newValue);
  insertPlaceList(List<Place> places) ;
  insertDeviceList(List<Device> device) ;
  Future<void> changeDeviceStatuses(String statusAddress, String status) ;
}

