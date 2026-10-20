import 'package:get/get.dart';

enum FloorCode{

  panelTak('T'),
  hamkaf('T0'),
  aval('T1'),
  dovom('T2'),
  sevom('T3'),
  chaharom('T4'),
  manfi1('T5'),
  manfi2('T6'),
  poshteBam('T7'),
  hayat('T8'),
  seraidari('T9'),
  nama('T10');

  const FloorCode(this.value);
  final String value;

  static FloorCode get(String value){
    switch(value){
      case 'T': return FloorCode.panelTak;
      case 'T0': return FloorCode.hamkaf;
      case 'T1': return FloorCode.aval;
      case 'T2': return FloorCode.dovom;
      case 'T3': return FloorCode.sevom;
      case 'T4': return FloorCode.chaharom;
      case 'T5': return FloorCode.manfi1;
      case 'T6': return FloorCode.manfi2;
      case 'T7': return FloorCode.poshteBam;
      case 'T8': return FloorCode.hayat;
      case 'T9': return FloorCode.seraidari;
      case 'T10': return FloorCode.nama;
    }

    return FloorCode.panelTak;
  }
}

extension FloorCodeExtension on FloorCode {

  String? get title => titles[this];
  static Map<FloorCode, String> titles = {
    FloorCode.panelTak: '',
    FloorCode.hamkaf: 't0'.tr,
    FloorCode.aval: 't1'.tr,
    FloorCode.dovom: 't2'.tr,
    FloorCode.sevom: 't3'.tr,
    FloorCode.chaharom: 't4'.tr,
    FloorCode.manfi1: 't5'.tr,
    FloorCode.manfi2: 't6'.tr,
    FloorCode.poshteBam: 't7'.tr,
    FloorCode.hayat: 't8'.tr,
    FloorCode.seraidari: 't9'.tr,
    FloorCode.nama: 't10'.tr,
  };
}