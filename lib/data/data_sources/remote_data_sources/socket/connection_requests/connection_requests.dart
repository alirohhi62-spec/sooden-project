import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/result.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/new_connection_wraper/new_location_data_model.dart';
import 'package:rxdart/rxdart.dart';

abstract class ConnectionRequests {
  disconnect();

  destroyConnections();

  BehaviorSubject<Result>  multiConnectionRequest();

  reconnectRequest();

  BehaviorSubject<Result> newLocationRequest(NewLocationDataModel newLocationDataModel) ;
}
