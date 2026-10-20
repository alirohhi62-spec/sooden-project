import 'package:get/get.dart';

enum PlaceCode{

  unknown(''),
  paziraie('A'),
  neshiman('B'),
  ashpazkhane('C'),
  matbakh('D'),
  khab('E'),
  rahro('F'),
  teras('G'),
  laundry('H'),
  rahPele('I'),
  hamam('J'),
  toilet('K'),
  ehzarAsansor('L'),
  iphoneTasviri('M'),
  motorkhane('N'),
  majmooeAbi('O'),
  anbari('P'),
  alachigh('Q');

  const PlaceCode(this.value);
  final String value;

  static PlaceCode get(String value){
    switch(value[0]){
      case 'A': return PlaceCode.paziraie;
      case 'B': return PlaceCode.neshiman;
      case 'C': return PlaceCode.ashpazkhane;
      case 'D': return PlaceCode.matbakh;
      case 'E': return PlaceCode.khab;
      case 'F': return PlaceCode.rahro;
      case 'G': return PlaceCode.teras;
      case 'H': return PlaceCode.laundry;
      case 'I': return PlaceCode.rahPele;
      case 'J': return PlaceCode.hamam;
      case 'K': return PlaceCode.toilet;
      case 'L': return PlaceCode.ehzarAsansor;
      case 'M': return PlaceCode.iphoneTasviri;
      case 'N': return PlaceCode.motorkhane;
      case 'O': return PlaceCode.majmooeAbi;
      case 'P': return PlaceCode.anbari;
      case 'Q': return PlaceCode.alachigh;
    }

    return PlaceCode.unknown;
  }
}

extension PlaceCodeExtension on PlaceCode {

  String? get title => titles[this];
  static Map<PlaceCode, String> titles = {
    PlaceCode.unknown: 'ناشناخته',
    PlaceCode.paziraie: 'A'.tr,
    PlaceCode.neshiman: 'B'.tr,
    PlaceCode.ashpazkhane: 'C'.tr,
    PlaceCode.matbakh: 'D'.tr,
    PlaceCode.khab: 'E'.tr,
    PlaceCode.rahro: 'F'.tr,
    PlaceCode.teras: 'G'.tr,
    PlaceCode.laundry: 'H'.tr,
    PlaceCode.rahPele: 'I'.tr,
    PlaceCode.hamam: 'J'.tr,
    PlaceCode.toilet: 'K'.tr,
    PlaceCode.ehzarAsansor: 'L'.tr,
    PlaceCode.iphoneTasviri: 'M'.tr,
    PlaceCode.motorkhane: 'N'.tr,
    PlaceCode.majmooeAbi: 'O'.tr,
    PlaceCode.anbari: 'P'.tr,
    PlaceCode.alachigh: 'Q'.tr,
  };
}