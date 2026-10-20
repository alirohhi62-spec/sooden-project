import 'package:geolocator/geolocator.dart';


abstract class UserLocationUseCase {
  Future<Position> getLocation();

}

