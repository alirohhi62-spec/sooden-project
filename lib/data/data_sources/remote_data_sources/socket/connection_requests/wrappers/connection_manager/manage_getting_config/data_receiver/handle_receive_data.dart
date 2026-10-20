import 'dart:convert';

import 'package:sprintf/sprintf.dart';

import '../../../../../../../../../core/eventbus/event_bus_const.dart';
import '../../../../../../../../../core/eventbus/event_bus_model.dart';
import '../../../../../../../../../core/utils/communication_constants.dart';
import '../../../../../../../../../core/utils/globals.dart';
import '../../../../../../../../../domain/usecases/update_devices/update_devices_usecase_impl.dart';
import '../../../../../../../../enums/headline_code.dart';

class HandleReceiveData {
  handleStatusData(List<int> data) async {
    _logger('handleStatusData', 'Data: ${data.join('|')}');

    List<String> bitArray = data.map((byte) => byte.toRadixString(2).padLeft(8, '0')).toList();
    _logger('handleStatusData', 'data : ${bitArray.join(',')}');

    var lookForOtherCommands = await _checkLightData(data);

    if (lookForOtherCommands) {
      var commandString = utf8.decode(data);
      if (_isBurglarAlarmData(commandString)) {
        _manageBurglarAlarmData(commandString);
      } else if (_isCurtainData(commandString)) {
        _manageCurtainData(commandString);
      }else if (_isFeedbackSetModem(commandString)) {
        _manageFeedbackSetModemData(commandString);
      }
    }
  }

  _checkLightData(List<int> data) async {
    String statusAddress = '', bytes = '';

    for (int i = 1; i < data.length; i++) {
      //print(data[i]);
      statusAddress = utf8.decode(data.sublist(0, i));
      var lastCharacter = statusAddress[statusAddress.length - 1];

      if (lastCharacter == HeadlineCode.light.value ||
          lastCharacter == HeadlineCode.temperature.value) {
        List<int> extraData = data.sublist(i);

        for (var byte in extraData) {
          bytes += sprintf("%08d", [int.parse(byte.toRadixString(2))]);
        }
        break;
      }
    }

    if (bytes.isNotEmpty) {
      _logger('handleStatusData', 'statusAddress:$statusAddress - \n bytes:${bytes.toString()}');
      await UpdateDeviceUseCaseImpl().changeDeviceStatuses(statusAddress, bytes);

      eventBus.fire(EventBusModel(event: EventBusConst.eventUpdatedDevice));
      return false;
    } else {
      return true;
    }
  }

  bool _isBurglarAlarmData(String commandString) {
   return commandString.contains(SocketConstants.requestBurglarAlarms);
  }

  void _manageBurglarAlarmData(String commandString) {
    eventBus
        .fire(EventBusModel(event: EventBusConst.eventNewBurglarAlarmData, data: commandString));
  }

  bool _isCurtainData(String commandString) {
    return commandString.contains(SocketConstants.headLineCurtain);
  }

  void _manageCurtainData(String commandString) {
    eventBus.fire(EventBusModel(event: EventBusConst.eventNewCurtainData, data: commandString));
  }

  bool _isFeedbackSetModem(String commandString) {
    return commandString.contains(SocketConstants.feedbackSetModemToDevice);
  }

  void _manageFeedbackSetModemData(String commandString) {
    eventBus.fire(EventBusModel(event: EventBusConst.eventNewFeedbackSetModemData, data: commandString));
  }

  void _logger(String key, String value) {
    doLogGlobal('handle_receive_data. H:$hashCode', key, value);
  }
}
