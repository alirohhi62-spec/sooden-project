import 'package:bms/domain/usecases/get_devices/get_devices_usecase_impl.dart';
import 'package:bms/presentation/logic/base_logic.dart';


import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:get/get.dart';

import '../../data/enums/floor_code.dart';
import '../../data/enums/headline_code.dart';

class PlaceTemperatureLogic extends BaseLogic {
  late FloorCode floor;
  late Place place;
  late String title;
  List<Device> devices = [];

  PlaceTemperatureLogic({required this.floor, required this.place});

  @override
  void onInit() {
    title = '${'temperature'.tr} ${place.getName()}';

    _initLights();

    super.onInit();
  }

  _initLights() async {
    devices = await   GetDeviceUseCaseImpl().getDevices(place.locationId!,
      floor: floor,
      placeCode: place.code!,
      headline: HeadlineCode.temperature,
    );

    update();
  }
}
