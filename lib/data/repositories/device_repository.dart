import 'package:bms/core/utils/communication_constants.dart';
import 'package:bms/data/data_sources/local_data_sources/database/app_database.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:get/get.dart';

import '../enums/floor_code.dart';
import '../enums/headline_code.dart';

class DeviceRepository {
  insertList(List<Device> device) async {
    await Get.find<AppDatabase>().deviceDao.insertList(device);
  }

  insertPlaces(List<Place> places) => Get.find<AppDatabase>().placeDao.insertList(places);

  Future<List<String>> getFloors(locationId) =>
      Get.find<AppDatabase>().deviceDao.getFloors(locationId);

  Future<List<Place>> getPlaces(int locationId, {String? floor}) =>
      Get.find<AppDatabase>().placeDao.getPlaces(
            locationId: locationId,
            floor: floor,
          );

  Future<bool> hasElevator({required int locationId, required String floor}) =>
      Get.find<AppDatabase>().placeDao.hasElevator(locationId: locationId, floor: floor);

  Future<List<Device>> getDevicesMuteHidden(int locationId, {
      required FloorCode floor,
      required String placeCode,
      required HeadlineCode headline}) {
    return Get.find<AppDatabase>().deviceDao.getDevicesMuteHidden(
          locationId: locationId,
          floor: floor.value,
          place: placeCode,
          headline: headline.value,
        );
  }

  Future<List<Device>> getDevices(int locationId,
      {
      required FloorCode floor,
      required String placeCode,
      required HeadlineCode headline}) {
    return Get.find<AppDatabase>().deviceDao.getDevices(
          locationId: locationId,
          floor: floor.value,
          place: placeCode,
          headline: headline.value,
        );
  }

  Future<List<Device>> getDevicesOfFloor(int locationId,
      {required FloorCode floor, required HeadlineCode headline}) {
    return Get.find<AppDatabase>().deviceDao.getDevicesOfFloor(
          locationId: locationId,
          floor: floor.value,
          headline: headline.value,
        );
  }

  Future<List<Device>> getDevicesByLocation({required int locationId}) {
    return Get.find<AppDatabase>().deviceDao.getDevicesByLocation(locationId: locationId);
  }

  Future<List<Device>> getBurglarAlarmDevices(int locationId) {
    return Get.find<AppDatabase>().deviceDao.getBurglarAlarmDevices(locationId);
  }

  updatePlace(Place place) {
    return Get.find<AppDatabase>().placeDao.update(place);
  }

  updateDevice(Device device) {
    return Get.find<AppDatabase>().deviceDao.update(device);
  }

  updateBurglarAlarmDevices(int locationId, String code, String value) {
    return Get.find<AppDatabase>()
        .deviceDao
        .updateBurglarAlarmDevices(locationId, SocketConstants.headLineBurglarAlarm, code, value);
  }

  updateCurtainDevices(Device device) {
    return Get.find<AppDatabase>().deviceDao.updateCurtainDevices(device);
  }
}
