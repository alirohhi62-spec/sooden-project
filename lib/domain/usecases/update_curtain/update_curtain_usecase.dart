import '../../../data/data_sources/local_data_sources/database/model/place.dart';

abstract class UpdateCurtainUseCase {
  update(Place place, String commandString)  ;
}

