import '../../../data/data_sources/local_data_sources/database/model/device.dart';
import '../../../data/data_sources/local_data_sources/database/model/place.dart';

abstract class ChangeLightStatusUsecase {
  requestChangeLight(Device device, Place place);
}
