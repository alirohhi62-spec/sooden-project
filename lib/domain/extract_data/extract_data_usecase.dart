import '../../data/model/parser_data_holder.dart';

abstract class ExtractDataUsecase{
  startParsing(mDeviceGottenConfig, currentLocationId, Function(ParserDataHolder) dataCallback)  ;

}