import 'package:bms/core/utils/communication_constants.dart';
import 'package:get/get.dart';

enum HeadlineCode {
  light(SocketConstants.headLineLight),
  curtain(SocketConstants.headLineCurtain),
  temperature(SocketConstants.headLineTemperature),
  scenarios(SocketConstants.headLineScenarios);

  const HeadlineCode(this.value);

  final String value;

  static HeadlineCode get(String value) {
    switch (value) {
      case SocketConstants.headLineLight:
        return HeadlineCode.light;
      case SocketConstants.headLineCurtain:
        return HeadlineCode.curtain;
      case SocketConstants.headLineTemperature:
        return HeadlineCode.temperature;
      case SocketConstants.headLineScenarios:
        return HeadlineCode.scenarios;
    }

    return HeadlineCode.light;
  }
}

extension HeadlineCodeExtension on HeadlineCode {
  String? get title => titles[this];
  static Map<HeadlineCode, String> titles = {
    HeadlineCode.light: 'light'.tr,
    HeadlineCode.temperature: 'temperature'.tr,
    HeadlineCode.curtain: 'shutters'.tr,
    HeadlineCode.scenarios: 'manage_scenarios'.tr,
  };
}
