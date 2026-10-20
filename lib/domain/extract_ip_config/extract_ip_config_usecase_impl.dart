import 'dart:convert';

import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/connection_manager/connection_manager_data_model.dart';
import 'package:bms/domain/extract_ip_config/extract_ip_config_usecase.dart';

class ExtractIpConfigDataUsecaseImpl extends ExtractIpConfigDataUsecase {
  /// Input Expectation: " %80:64:6f:ae:cf:90+192.168.43.96   +Redmi Note 9 Pro".
  ///  " %80:64:6f:ae:cf:90"
  @override
  Future<IpConfigModel> parseData(List<int> inputDataList) async {
    inputDataList = _removeNullValues(inputDataList);
    String inputData = utf8.decode(inputDataList);
    List<String> output = _extractByRegExp(inputData);

    return IpConfigModel(
        macAddress: _getAtOrNull(output, 0),
        ipPanelOnModem: _extractIpPanelOnModem(_getAtOrNull(output, 1)),
        modemWifiName: _extractWifiName(_getAtOrNull(output, 2)));
  }

  _removeNullValues(List<int> inputDataList) {
    return inputDataList.where((item) => item != 0).toList();
  }

  _extractByRegExp(String inputData) {
    // Define a regex pattern to match the '+' or '%' characters
    RegExp pattern = RegExp(r'[+%]');
    List<String> output = inputData.split(pattern);
    // Now output is ["", "80:64:6f:ae:cf:90", "192.168.43.96", "Redmi Note 9 Pro"]

    if (output.isNotEmpty) {
      output.removeAt(0); // Remove the first empty string
    }
    return output;
  }

  String? _getAtOrNull(List<String> output, int index) {
    if (output.length > index) {
      return output[index];
    } else {
      return null;
    }
  }

  String? _extractIpPanelOnModem(String? ipPanelOnModem) {
    if (ipPanelOnModem == null) {
      return null;
    } else {
      ipPanelOnModem = ipPanelOnModem.trim();
      return _getDataOrNull(ipPanelOnModem);
    }
  }

  String? _extractWifiName(String? wifiName) {
    if (wifiName == null) {
      return null;
    } else {
      return _getDataOrNull(wifiName);
    }
  }

  String? _getDataOrNull(String dataMayEmpty) {
    if (dataMayEmpty.isEmpty) {
      return null;
    } else {
      return dataMayEmpty;
    }
  }
}
