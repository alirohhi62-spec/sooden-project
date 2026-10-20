
import '../../core/utils/globals.dart';
import '../../data/data_sources/local_data_sources/database/model/device.dart';
import '../../data/data_sources/local_data_sources/database/model/place.dart';
import '../../data/model/parser_data_holder.dart';
import 'extract_data_usecase.dart';

class ExtractDataUsecaseImpl extends ExtractDataUsecase {

  @override
  startParsing(mDeviceGottenConfig, currentLocationId, Function(ParserDataHolder) dataCallback)  {
    ParserDataHolder dataHolder = ParserDataHolder();

    _logger('_fillLocationTables', 'deviceGottenConfig : $mDeviceGottenConfig');

    mDeviceGottenConfig!
        .substring(0, mDeviceGottenConfig!.indexOf('+'))
        .split('#')
        .sublist(1)
        .forEach((floorSection) {
      String floor = floorSection.split('*')[0];
      _logger('_fillLocationTables', 'floor : $floor');

      floorSection.split('*').sublist(1).forEach((placeSection)  {
        String placeStr = _parsePlace(placeSection, currentLocationId, dataHolder.places, floor);
        var devices = _parseDevices(placeSection, currentLocationId, floor, placeStr);
        dataHolder.devices.addAll(devices);
      });
    });

    printLogs(dataHolder);

    var securityDevices = _parseSecurityDevices(currentLocationId, mDeviceGottenConfig!);
    dataHolder.devices.addAll(securityDevices);

    _logger('startParsing', 'Data parse done.');
    dataCallback.call(dataHolder);
  }

  void printLogs(ParserDataHolder dataHolder) {
    _logger('_fillLocationTables', 'places. : ${dataHolder.places.length}');

    for (int i = 0; i < dataHolder.places.length; i++) {
      _logger('_fillLocationTables', 'place: $i ${dataHolder.places[i].code}');
    }
  }

// test : secConfig : #X1*Z
  List<Device> _parseSecurityDevices(currentLocationId, String mDeviceGottenConfig) {
    var secConfig = mDeviceGottenConfig.substring(mDeviceGottenConfig.indexOf('+') + 1);

    List<Device> devices = [];

    // It's the data that we expect: #X1*Z1*Z2*Z3*Z4++
    _logger('_parseSecurityDevices', 'secConfig : $secConfig');

    var array = RegExp(r'X\d+|Z+\d*').allMatches(secConfig).map((m) => m.group(0)).toList();

    // We make it to an array [0:'X1', 1:'Z1', 2:'Z2', 3:'Z3' ...]
    _logger('_parseSecurityDevices', 'array : ${array.join('-')}');

    // i = 1, Because in '0' position of array is 'X1'
    for (int i = 1; i < array.length; i++) {
      var model = Device(
          locationId: currentLocationId, floor: null, place: null, headline: 'X1', code: array[i]!);
      devices.add(model);
    }
    return devices;
  }

  _parseDevices(placeSection, currentLocationId, String floor, String place)   {
    List<Device> devices = [];
    placeSection.split('/').sublist(1).forEach((headlineSection) {
      String headline = headlineSection[0];
      _logger('_fillLocationTables', 'headline : $headline');

      RegExp(r'.\d*')
          .allMatches(headlineSection.substring(1))
          .map((match) => match.group(0))
          .toList()
          .forEach((element)   {
        _logger('_fillLocationTables', 'element : $element');
        _logger('_fillLocationTables', 'location!.id : $currentLocationId');

        devices.add(Device(
          locationId: currentLocationId,
          floor: floor,
          place: place,
          headline: headline,
          code: element,
        ));
      });
    });
    return devices;
  }

  _parsePlace(placeSection, currentLocationId, List<Place> places, String floor)  {
    String place =
    RegExp(r'.\d*').allMatches(placeSection).map((match) => match.group(0)).toList()[0]!;

    _logger('parsePlace', 'place : $place');
    _logger('parsePlace', 'location?.id : $currentLocationId');

    _addPlaceToList(places, currentLocationId, floor, place);
    return place;
  }

  void _addPlaceToList(List<Place> places, currentLocationId, String floor, String place) {
    places.add(Place(
      locationId: currentLocationId,
      floor: floor,
      code: place,
      name: null,
    ));
  }

  void _logger(String key, String value) {
    doLogGlobal('extract_data_usecase_impl. H:$hashCode', key, value);
  }
}
