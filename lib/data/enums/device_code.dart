import 'package:get/get.dart';

enum DeviceCode {
  loostr('a'),
  halojen('b'),
  divarkoob('c'),
  noormakhfi('d'),
  liner('e'),
  aviz('f'),
  havakesh('g'),
  mahtabi('h'),
  projector('i'),
  cheraghDafni('j'),
  cheraghNama('k'),
  cheraghParki('l'),
  shirBarghi('m'),
  pump('n'),
  motor('o'),
  pardeBarghi('p'),
  kerkereRolup('q'),
  darbBarghi('r'),
  koolerGazi('s'),
  koolerAbi('t'),
  fanQuel('u'),
  darbBazKon('v'),
  package('w');

  const DeviceCode(this.value);

  final String value;

  static DeviceCode get(String value) {
    switch (value[0]) {
      case 'a':
        return DeviceCode.loostr;
      case 'b':
        return DeviceCode.halojen;
      case 'c':
        return DeviceCode.divarkoob;
      case 'd':
        return DeviceCode.noormakhfi;
      case 'e':
        return DeviceCode.liner;
      case 'f':
        return DeviceCode.aviz;
      case 'g':
        return DeviceCode.havakesh;
      case 'h':
        return DeviceCode.mahtabi;
      case 'i':
        return DeviceCode.projector;
      case 'j':
        return DeviceCode.cheraghDafni;
      case 'k':
        return DeviceCode.cheraghNama;
      case 'l':
        return DeviceCode.cheraghParki;
      case 'm':
        return DeviceCode.shirBarghi;
      case 'n':
        return DeviceCode.pump;
      case 'o':
        return DeviceCode.motor;
      case 'p':
        return DeviceCode.pardeBarghi;
      case 'q':
        return DeviceCode.kerkereRolup;
      case 'r':
        return DeviceCode.darbBarghi;
      case 's':
        return DeviceCode.koolerGazi;
      case 't':
        return DeviceCode.koolerAbi;
      case 'u':
        return DeviceCode.fanQuel;
      case 'v':
        return DeviceCode.darbBazKon;
      case 'w':
        return DeviceCode.package;
    }

    return DeviceCode.loostr;
  }
}

extension DeviceCodeExtension on DeviceCode {
  String? get title => titles[this];
  static Map<DeviceCode, String> titles = {
    DeviceCode.loostr: 'a'.tr,
    DeviceCode.halojen: 'b'.tr,
    DeviceCode.divarkoob: 'c'.tr,
    DeviceCode.noormakhfi: 'd'.tr,
    DeviceCode.liner: 'e'.tr,
    DeviceCode.aviz: 'f'.tr,
    DeviceCode.havakesh: 'g'.tr,
    DeviceCode.mahtabi: 'h'.tr,
    DeviceCode.projector: 'i'.tr,
    DeviceCode.cheraghDafni: 'j'.tr,
    DeviceCode.cheraghNama: 'k'.tr,
    DeviceCode.cheraghParki: 'l'.tr,
    DeviceCode.shirBarghi: 'm'.tr,
    DeviceCode.pump: 'n'.tr,
    DeviceCode.motor: 'o'.tr,
    DeviceCode.pardeBarghi: 'p'.tr,
    DeviceCode.kerkereRolup: 'q'.tr,
    DeviceCode.darbBarghi: 'r'.tr,
    DeviceCode.koolerGazi: 's'.tr,
    DeviceCode.koolerAbi: 't'.tr,
    DeviceCode.fanQuel: 'u'.tr,
    DeviceCode.darbBazKon: 'v'.tr,
    DeviceCode.package: 'w'.tr,
  };

  String? get icon => icons[this];
  static Map<DeviceCode, String> icons = {
    DeviceCode.loostr: 'assets/icons/lustre.svg',
    DeviceCode.halojen: 'assets/icons/halozhen.svg',
    DeviceCode.divarkoob: 'assets/icons/wall-light.svg',
    DeviceCode.noormakhfi: 'assets/icons/secret-light.svg',
    DeviceCode.liner: 'assets/icons/linear.svg',
    DeviceCode.aviz: 'assets/icons/pendant-light.svg',
    DeviceCode.havakesh: 'assets/icons/ventilator.svg',
    DeviceCode.mahtabi: 'assets/icons/fluorescent.svg',
    DeviceCode.projector: 'assets/icons/projector.svg',
    DeviceCode.cheraghDafni: 'assets/icons/light-max.svg',
    DeviceCode.cheraghNama: 'assets/icons/headlight.svg',
    DeviceCode.cheraghParki: 'assets/icons/streetlight.svg',
    DeviceCode.shirBarghi: 'assets/icons/smart-faucet.svg',
    DeviceCode.pump: 'assets/icons/water-pump.svg',
    DeviceCode.motor: 'assets/icons/engine.svg',
    DeviceCode.kerkereRolup: 'assets/icons/curtain.svg',
    DeviceCode.pardeBarghi: 'assets/icons/curtain.svg',
    DeviceCode.darbBarghi: 'assets/icons/garage.svg',
    DeviceCode.koolerGazi: 'assets/icons/air-conditioner.svg',
    DeviceCode.koolerAbi: 'assets/icons/air-conditioner-wind.svg',
    DeviceCode.fanQuel: 'assets/icons/fan.svg',
    DeviceCode.darbBazKon: 'assets/icons/door-lock.svg',
    DeviceCode.package: 'assets/icons/radiator.svg',
  };
}
