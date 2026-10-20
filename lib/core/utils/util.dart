import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/values/theme.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:lottie/lottie.dart';

class Utils {
  static bool checkIfDarkModeEnabled(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.brightness == Brightness.dark;
  }

  static bool isTablet() => MediaQuery.of(Get.context!).size.shortestSide >= 600;

  static double optimizeDimenBase(double value) {
    var ratio = MediaQuery.of(Get.context!).devicePixelRatio;

    return value * (ratio == 4 ? 2.5 : ratio) * (isTablet() ? 2 : 1);
  }

  static MobileSize screenType() {
    double screenSize = MediaQuery.of(Get.context!).size.width;
    if (screenSize > 600) {
      return MobileSize.large;
    } else if (screenSize > 350 && screenSize < 600) {
      return MobileSize.normal;
    } else {
      return MobileSize.small;
    }
  }

  static snackSuccess(String msg) {
    Get.closeAllSnackbars();
    Get.showSnackbar(
      GetSnackBar(
        message: msg,
        icon: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12),
          child: Lottie.asset('assets/lottie/lottie_success.json', width: 24, height: 24),
        ),
        duration: Duration(seconds: (msg.length * 0.1).round() + 1),
        borderRadius: 10,
        margin: EdgeInsets.all(16.0.sp),
        backgroundColor: AppTheme().green,
        padding: EdgeInsets.all(12.0.sp),
        snackPosition: /*isTop ? */ SnackPosition.TOP /*: SnackPosition.BOTTOM*/,
      ),
    );
  }

  static toast(String msg, Toast? toastLength) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength: toastLength,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 14.0);
  }

  static snackError(String msg) {
    Get.closeAllSnackbars();
    Get.showSnackbar(
      GetSnackBar(
        message: msg,
        icon: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12),
          child: Lottie.asset('assets/lottie/lottie-error.json', width: 24, height: 24),
        ),
        duration: Duration(seconds: (msg.length * 0.1).round() + 1),
        borderRadius: 10,
        margin: EdgeInsets.all(16.0.sp),
        backgroundColor: AppTheme().red,
        padding: EdgeInsets.all(12.0.sp),
        snackPosition: /*isTop ? */ SnackPosition.TOP /*: SnackPosition.BOTTOM*/,
      ),
    );
  }

  static sdkVersion() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }
}

class CardNumberFormatter extends TextInputFormatter {
  final sampleNumber = '0000 0000 0000 0000';

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length > oldValue.text.length) {
      if (newValue.text.length > sampleNumber.length) {
        return oldValue;
      }

      final lastEnteredLetter = newValue.text.substring(newValue.text.length - 1);
      if (!RegExp(r'[0-9]').hasMatch(lastEnteredLetter)) {
        return oldValue;
      }

      if (newValue.text.isNotEmpty && sampleNumber[newValue.text.length - 1] == ' ') {
        return TextEditingValue(
          text: '${oldValue.text} ${newValue.text.substring(newValue.text.length - 1)}',
          selection: TextSelection.collapsed(offset: newValue.selection.end + 1),
        );
      }
    }
    return newValue;
  }
}

enum MobileSize { small, normal, large }

Future<void> enableGPS() async {
  // Create an instance of the location package
  Location location = new Location();

  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  LocationData _locationData;

  // Check if the GPS service is enabled
  _serviceEnabled = await location.serviceEnabled();
  if (!_serviceEnabled) {
    // Request the user to enable GPS
    _serviceEnabled = await location.requestService();
    if (!_serviceEnabled) {
      // If the user refuses to turn on GPS, return from the function
      return;
    }
  }

  // Check if the app has permission to access location
  _permissionGranted = await location.hasPermission();
  if (_permissionGranted == PermissionStatus.denied) {
    // Request location permission from the user
    _permissionGranted = await location.requestPermission();
    if (_permissionGranted != PermissionStatus.granted) {
      // If permission is not granted, return from the function
      return;
    }
  }

  // Once GPS is enabled and permissions are granted, get the location
  _locationData = await location.getLocation();
  print("Location: ${_locationData.latitude}, ${_locationData.longitude}");
}
