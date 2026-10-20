import 'dart:convert';
import 'dart:typed_data';

import 'package:bms/core/utils/communication_constants.dart';
import 'package:bms/data/enums/headline_code.dart';
import 'package:bms/domain/usecases/run_scenario/run_scenario_usecase.dart';

import '../../../core/utils/globals.dart';
import '../../../core/utils/util.dart';
import '../../../data/data_sources/local_data_sources/database/model/scenario.dart';
import '../../../data/data_sources/local_data_sources/database/model/scenario_det.dart';
import '../../../data/data_sources/remote_data_sources/socket/socket.dart';
import '../get_scenario/get_scenario_usecase.dart';
import '../get_scenario/get_scenario_usecase_impl.dart';

class RunScenarioUseCaseImpl implements RunScenarioUseCase {
  late GetScenarioUseCase _getScenarioUseCase;

  RunScenarioUseCaseImpl() {
    _getScenarioUseCase = GetScenarioUseCaseImpl();
  }

  @override
  Future<void> runScenario(Scenario scenario) async {
    List<ScenarioDet> devices = await _getScenarioUseCase.getScenarioDet(scenario.id!);

    String startCommand = _makeScenarioCommand(scenario);

    _logger("runScenario", " devices.length: ${devices.length}");

    Uint8List commandUint8list = Uint8List.fromList(utf8.encode(startCommand));

    var message = Uint8List((startCommand.length + devices.length / 2).toInt());
    var byteData = ByteData.view(message.buffer);

    commandUint8list.asMap().forEach((index, value) => byteData.setUint8(index, value));
    _logger("runScenario", " byteData: $byteData  ");

    var bits = createBits(devices);

    _splitBitsArrayToByte(bits, byteData, commandUint8list);

    _logger("runScenario", 'The final message: $message');

    _doRunScenario(message);
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

  String _makeScenarioCommand(Scenario scenario) {
    String startCommand = '';
    if (scenario.floor == null && scenario.place == null) {
      // General
      startCommand = SocketConstants.commandScenarioGeneral;
    } else if (scenario.floor != null && scenario.place == null) {
      // Floor : !^T1
      startCommand = '${SocketConstants.commandScenarioFloor}${scenario.floor!}';
    } else if (scenario.floor != null && scenario.place != null) {
      // Place: !~T1A1
      startCommand = '${SocketConstants.commandScenarioPlace}${scenario.floor!}${scenario.place!}';
    }
    _logger("makeScenarioCommand", 'The startCommand: $startCommand');
    return startCommand;
  }

// Function to create bits for each device
  List<int> createBits(List<ScenarioDet> devices) {
    List<int> bits = [];
    for (var device in devices) {
      // Check if the device is a light
      if (device.headline == HeadlineCode.light.value) {
        _addBitForLight(bits, device);
      }
      // Check if the device is a curtain
      else if (device.headline == HeadlineCode.curtain.value) {
        _addBitForCurtain(bits, device);
      }
    }
    return bits;
  }

// Function to add bit for a light device
  void _addBitForLight(List<int> bits, ScenarioDet device) {
    // Check if the device is hidden
    if (isHiddenDevice(device)) {
      _addBitForHiddenDevice(bits);
    } else {
      // Add bit based on the value of the light
      bits.add(device.value == 'true' ? 1 : 0);
    }
  }

// Function to add bit for a hidden device
  void _addBitForHiddenDevice(List<int> bits) {
    bits.add(0);
  }

// Function to add bit for a curtain device
  void _addBitForCurtain(List<int> bits, ScenarioDet device) {
    // Check if the device is hidden
    if (isHiddenDevice(device)) {
      _addBitForHiddenDevice(bits);
    } else {
      // Add bit based on the value of the curtain
      switch (device.value) {
        case SocketConstants.curtainClose:
          _addBitToCloseCurtain(bits);
          break;

        case SocketConstants.curtainOpen:
          _addBitToOpenCurtain(bits);
          break;

        case SocketConstants.curtainStop:
          _addBitToStopCurtain(bits);
          break;
      }
    }
  }

// Function to add bits to open the curtain
  void _addBitToOpenCurtain(List<int> bits) {
    bits.addAll([1, 0]);
  }

// Function to add bits to close the curtain
  void _addBitToCloseCurtain(List<int> bits) {
    bits.addAll([0, 1]);
  }

// Function to add bits to stop the curtain
  void _addBitToStopCurtain(List<int> bits) {
    bits.addAll([0, 0]);
  }

// Function to check if the device is hidden
  bool isHiddenDevice(ScenarioDet device) => device.code == SocketConstants.hiddenDevice;

  void _doRunScenario(Uint8List message) {
    late final Socket socket = Socket.instance;

    socket.send(message);
    Utils.snackSuccess('دستور اجرای سناریو ارسال شد');
  }

  void _logger(String key, String value) {
    doLogGlobal('run_scenario_usecase_impl. H:$hashCode', key, value);
  }
}
