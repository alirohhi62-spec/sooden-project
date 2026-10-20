import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bms/domain/usecases/change_light_status/change_light_status_usecase.dart';
import 'package:bms/domain/usecases/send_data/send_data_socket_usecase_impl.dart';

import '../../../core/utils/communication_constants.dart';
import '../../../core/utils/globals.dart';
import '../../../data/data_sources/local_data_sources/database/model/device.dart';
import '../../../data/data_sources/local_data_sources/database/model/place.dart';
import '../../../data/enums/floor_code.dart';
import '../../../data/enums/headline_code.dart';
import '../get_devices/get_devices_usecase_impl.dart';
import '../send_data/send_data_socket_usecase.dart';

class ChangeLightStatusUsecaseImpl extends ChangeLightStatusUsecase {
  final SendDataSocketUsecase _mSendData = SendDataSocketUsecaseImpl();
  Timer? _mTimer;
  final List<Device> _mDeviceList = [];

  @override
  requestChangeLight(Device device, Place place) {
    _logger("requestChangeLight", 'Method Called device: ${device.id}');

    _mTimer ??= Timer(const Duration(milliseconds:SocketConstants.requestChangeLightTimer), () {
      _logger("requestChangeLight", 'Timer happen');

      _mTimer = null;
      _doRequest(List<Device>.from(_mDeviceList), place);
      _mDeviceList.clear();
      _logger("requestChangeLight", 'End');
    });

    _mDeviceList.add(device);
    _logger("requestChangeLight", '_mDeviceList.length ${_mDeviceList.length}');
  }

  _doRequest(List<Device> deviceList, Place place) async {
    _logger("_doRequest", 'deviceList.length ${deviceList.length}');

    Uint8List message = await _createCommands(deviceList, place);
    _mSendData.send(message);
  }

  _createCommands(List<Device> selectedDevices, Place place) async {
    List<Device> allDevices = await _getAllDevices(place, selectedDevices);

    String startCommand = _makeStartCommand(selectedDevices[0]);
    Uint8List commandUint8list = Uint8List.fromList(utf8.encode(startCommand));

    var message = Uint8List((startCommand.length + (allDevices.length / 8).floor() + 1).toInt());
    var byteData = ByteData.view(message.buffer);

    commandUint8list.asMap().forEach((index, value) => byteData.setUint8(index, value));
    _logger("_createCommands", " byteData: $byteData  ");

    var bits = createBits(allDevices, selectedDevices);
    _splitBitsArrayToByte(bits, byteData, commandUint8list);

    _logger("_createCommands", 'The final message: $message');

    return message;
  }

  Future<List<Device>> _getAllDevices(Place place, List<Device> selectedDevices) async {
    List<Device> allDevices = await GetDeviceUseCaseImpl().getDevices(
      place.locationId!,
      floor: FloorCode.get(selectedDevices[0].floor!),
      placeCode: place.code!,
      headline: HeadlineCode.light,
    );
    return allDevices;
  }

  String _makeStartCommand(Device device) {
    String startCommand = '';

    startCommand = '${SocketConstants.command}${device.floor}${device.place}${device.headline}';
    _logger("_makeStartCommand", 'The startCommand: $startCommand');
    return startCommand;
  }

  List<int> createBits(List<Device> allDevices, List<Device> selectedDevices) {
    _logger("createBits", 'selectedDevices.length ${selectedDevices.length}');

    List<int> bits = [];
    for (var device in allDevices) {
      try {
        if (isDeviceSelected(device, selectedDevices)) {
          bits.add(1);
        }
        else {
          bits.add(0);
        }
      } catch (ex) {
        bits.add(0);
      }
    }
    return bits;
  }

  isDeviceSelected(Device device, List<Device> selectedDevices) {
    for (int k = 0; k < selectedDevices.length; k++) {
      if (device.id == selectedDevices[k].id) {
        _logger("isDeviceSelected", 'is Equal id: ${selectedDevices[k].id}');
        return true;
      }
    }
    return false;
  }


void _splitBitsArrayToByte(List<int> bits, ByteData byteData, Uint8List commandUint8list) {
  for (var i = 0; i < bits.length; i += 8) {
    var end = (i + 8 < bits.length) ? i + 8 : bits.length;
    var slice = bits.sublist(i, end);
    if (slice.length < 8) {
      for (var j = slice.length; j < 8; j++) {
        slice.add(0);
      }
    }
    var byte = int.parse(slice.join(), radix: 2);
    byteData.setUint8(commandUint8list.length + i ~/ 8, byte);
  }
}

void _logger(String key, String value) {
  doLogGlobal('change_light_status_usecase_impl. H:$hashCode', key, value);
}
}
