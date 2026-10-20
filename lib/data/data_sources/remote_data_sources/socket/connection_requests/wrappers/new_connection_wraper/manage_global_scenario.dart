import 'package:get/get.dart';

import '../../../../../../../core/utils/communication_constants.dart';
import '../../../../../../../domain/usecases/get_devices/get_devices_usecase_impl.dart';
import '../../../../../../../domain/usecases/update_scenario/update_scenario_usecase.dart';
import '../../../../../../../domain/usecases/update_scenario/update_scenario_usecase_impl.dart';
import '../../../../../../enums/headline_code.dart';
import '../../../../../local_data_sources/database/model/device.dart';
import '../../../../../local_data_sources/database/model/scenario.dart';
import '../../../../../local_data_sources/database/model/scenario_det.dart';

class ManageGlobalScenario {
  final UpdateScenarioUseCase _mUpdateScenarioUseCase = UpdateScenarioUseCaseImpl();

  createGeneralScenarios(currentLocationId) async {
    List<Device> locationDevices =
        await GetDeviceUseCaseImpl().getDevicesByLocation(locationId: currentLocationId);

    await _insertExitScenario(currentLocationId, locationDevices);

    await _insertEnterScenario(currentLocationId, locationDevices);


  }

  Future<void> _insertExitScenario(currentLocationId, List<Device> locationDevices) async {
    int scenarioExitId = await _mUpdateScenarioUseCase.insertScenario(Scenario(
      locationId: currentLocationId,
      name: 'exit'.tr,
    ));

    for (var element in locationDevices) {
      if (element.headline == HeadlineCode.light.value) {
        ScenarioDet scenarioDet = ScenarioDet(
          scenarioId: scenarioExitId,
          deviceId: element.id,
          value: 'false',
        );

        _mUpdateScenarioUseCase.insertScenarioDet(scenarioDet);
      } else if (element.headline == HeadlineCode.curtain.value) {
        ScenarioDet scenarioDet = ScenarioDet(
          scenarioId: scenarioExitId,
          deviceId: element.id,
          value: SocketConstants.curtainClose,
        );

        _mUpdateScenarioUseCase.insertScenarioDet(scenarioDet);
      }
    }
  }

  Future<UpdateScenarioUseCase> _insertEnterScenario(
      currentLocationId, List<Device> locationDevices) async {
    int scenarioEnterId = await _mUpdateScenarioUseCase.insertScenario(Scenario(
      locationId: currentLocationId,
      name: 'enter'.tr,
    ));

    for (var element in locationDevices) {
      if (element.headline == HeadlineCode.light.value) {
        ScenarioDet scenarioDet = ScenarioDet(
          scenarioId: scenarioEnterId,
          deviceId: element.id,
          value: 'true',
        );

        _mUpdateScenarioUseCase.insertScenarioDet(scenarioDet);
      } else if (element.headline == HeadlineCode.curtain.value) {
        ScenarioDet scenarioDet = ScenarioDet(
          scenarioId: scenarioEnterId,
          deviceId: element.id,
          value: SocketConstants.curtainOpen,
        );

        _mUpdateScenarioUseCase.insertScenarioDet(scenarioDet);
      }
    }
    return _mUpdateScenarioUseCase;
  }
}
