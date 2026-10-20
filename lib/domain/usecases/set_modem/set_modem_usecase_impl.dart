import 'package:bms/data/repositories/location_repository.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';

import '../../../core/utils/communication_constants.dart';
import '../../../core/utils/globals.dart';
import '../../../data/data_sources/local_data_sources/database/model/location.dart';
import 'set_modem_usecase.dart';

class SetModemUsecaseImpl implements SetModemUsecase {
  late final LocationRepository _locationRepository = Get.find<LocationRepository>();

  @override

  /// Sample :
  /// @M_S=192.168.0.76
  /// @M_S=Repeat
  /// @M_S=Error
  setModemData(Location locationToEdit, Object data,
      Function(bool status, String data) resultFeedback) async {
    String commandString = data as String;

    if (_isError(commandString)) {
      _onError(resultFeedback);
    } else if (_isRepeat(commandString)) {
      _onRepeat(resultFeedback);
    } else {
      await _onSuccess(commandString, locationToEdit, resultFeedback);
    }
  }

  bool _isError(String commandString) {
    return commandString.contains(SocketConstants.feedbackSetModemIncorrectData);
  }

  void _onError(Function(bool status, String data) resultFeedback) {
    resultFeedback.call(false, 'احتمالا اسم مودم یا پسورد اشتباه است. لطفا دوباره بررسی کنید');
    _logger('setModemData', '_isError');
  }

  bool _isRepeat(String commandString) {
    return commandString.contains(SocketConstants.feedbackSetModemNeedToTryAgain);
  }

  void _onRepeat(Function(bool status, String data) resultFeedback) {
    resultFeedback.call(false, 'لطفا دوباره تلاش کنید');
    _logger('setModemData', '_isRepeat');
  }

  Future<void> _onSuccess(String commandString, Location locationToEdit,
      Function(bool status, String data) resultFeedback) async {
    String ip =_extractIp(commandString);
    await _updateIpInDb(locationToEdit, ip);
    resultFeedback.call(true, ip);
    _logger('setModemData', 'Success - ip: $ip');
  }

  _extractIp(String commandString){
    // The if value == 0 part is to ignore null characters (ASCII value 0)
    RegExp exp =  RegExp(r"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b");
    String? ipAddress = exp.stringMatch(commandString);
    return ipAddress;
  }

  _updateIpInDb(Location locationToEdit, String ip) async {
    locationToEdit.panelIpOnModem = ip;
    await _locationRepository.updateLocation(locationToEdit);
  }

  void _logger(String key, String value) {
    doLogGlobal('set_modem_usecase_impl. H:$hashCode', key, value);
  }
}
