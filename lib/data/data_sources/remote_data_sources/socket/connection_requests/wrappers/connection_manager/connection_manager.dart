import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/new_connection_wraper/new_location_data_model.dart';

import '../../../../../local_data_sources/database/model/location.dart';
import '../../result.dart';

abstract class ConnectionManager {

  void setData(Function(Result) resultCallback, {NewLocationDataModel? model});

  void connectByLocation(Location location);

  void connect();

}
