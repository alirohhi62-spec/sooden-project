import '../../../data/data_sources/local_data_sources/database/model/scenario.dart';

abstract class RunScenarioUseCase {
  Future<void> runScenario(Scenario scenario);
}
