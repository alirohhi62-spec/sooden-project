import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/connection_manager/connection_manager_data_model.dart';

abstract class ExtractIpConfigDataUsecase{

  Future<IpConfigModel> parseData(List<int> inputData);

}