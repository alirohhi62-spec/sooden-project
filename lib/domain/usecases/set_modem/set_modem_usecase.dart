import '../../../data/data_sources/local_data_sources/database/model/location.dart';

abstract class SetModemUsecase {
  setModemData(Location locationToEdit,String commandString, Function(bool status, String data) resultFeedback);
}
