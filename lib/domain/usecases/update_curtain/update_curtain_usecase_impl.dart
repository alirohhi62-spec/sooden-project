import 'package:bms/core/utils/communication_constants.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:get/get.dart';

import '../../../core/utils/globals.dart';
import '../../../data/data_sources/local_data_sources/database/model/place.dart';
import '../../../data/repositories/device_repository.dart';
import 'update_curtain_usecase.dart';

class UpdateCurtainUseCaseImpl implements UpdateCurtainUseCase {
  late final DeviceRepository _deviceRepository = Get.find<DeviceRepository>();

  @override
  /// Samples that we expect : '@T1A1Vp1-9S/q1-0S/p2-4C/q2-9S/p3-7O or '@TA1Vp1-9C'
  update(Place place, String commandString) async {
    _logger('updateCurtain', 'commandString: $commandString');

    RegExp regExp = RegExp(r"([a-z0-9]+)-([0-9]+)([A-Z])");

    Iterable<RegExpMatch> matches = regExp.allMatches(commandString);
    for (RegExpMatch match in matches) {
      var code = match.group(1); // p1
      var secondValue = match.group(2); //9
      var value = match.group(3); //C

      Device device = Device(
          locationId: place.locationId,
          floor: place.floor,
          place: place.code,
          headline: SocketConstants.headLineCurtain,
          code: code,
          value: value,
          secondValue: secondValue);

      await _deviceRepository.updateCurtainDevices(device);
    }
  }

  void _logger(String key, String value) {
    doLogGlobal('update_curtain_usecase_impl. H:$hashCode', key, value);
  }
}
