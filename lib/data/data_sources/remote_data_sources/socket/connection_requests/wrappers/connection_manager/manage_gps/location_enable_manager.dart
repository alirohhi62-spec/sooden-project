
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';

import '../../../../../../../../core/utils/util.dart';

class LocationEnableManager {
  Future<bool> isLocationEnabled() async {
    var hasLocationPermission = await _checkPermission(4);

    if (hasLocationPermission) {
      var isGpsOn = _checkTurnGpsOn();
      return isGpsOn;
    } else {
      return false;
    }
  }

  Future<bool> _checkPermission(int repeatCount) async {
    if (repeatCount == 0) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (_noPermission(permission)) {
      LocationPermission permission = await Geolocator.requestPermission();
      if (_hasPermission(permission)) {
        return true;
      } else {
        return _checkPermission(repeatCount - 1);
      }
    } else if (_noPermissionForEver(permission)) {
      Utils.snackError(
          'مجوز موقعیت مکانی برای همیشه از برنامه گرفته شده است.  لطفا از طریق تنظیمات اندروید، این محدودیت را بردارید.');
      return false;
    } else {
      // Means has permission
      return true;
    }
  }

  bool _noPermissionForEver(LocationPermission permission) =>
      permission == LocationPermission.deniedForever;

  bool _noPermission(LocationPermission permission) {
    return permission == LocationPermission.unableToDetermine ||
        permission == LocationPermission.denied;
  }

  bool _hasPermission(LocationPermission permission) =>
      permission == LocationPermission.whileInUse || permission == LocationPermission.always;

  Future<bool> _checkTurnGpsOn() async {
    Location gps = Location();
    bool serviceEnabled = await gps.serviceEnabled();

    if (serviceEnabled) {
      return true;
    } else {
      return await _requestTurnGpsOn(serviceEnabled, gps);
    }
  }



  Future<bool> _requestTurnGpsOn(bool serviceEnabled, Location gps) async {
    if (await _isAbleToTurnGpsOn()) {
      return await gps.requestService();
    } else {
      return false;
    }
  }

  Future<bool> _isAbleToTurnGpsOn() async {
    int sdkVersion = await Utils.sdkVersion();
    return sdkVersion >= 33;
  }
}
