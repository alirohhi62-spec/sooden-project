library bms.globals;

import 'package:event_bus/event_bus.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../data/repositories/logger/logger_repo_impl.dart';
import '../eventbus/event_bus_const.dart';

EventBus eventBus = EventBus();
const String WEATHER_BASE_URL = 'https://api.open-meteo.com/v1';
bool testWithoutPanel = false;
bool isLoggerEnable = true;

String currentMockConfig = _mockConfig4;

String _mockConfig =
    '#T0*A/Uaabbcd/Vqqpp/Wsw*B/Uaabbbdek/Vqp/Wsw*C/Uabde/Ww*E/Uabcd/Vqp/Wsw*G/Ub*I/Ub*J/Ubcg*K/Ubcg#T1*B/Uaabbcd/Vq/Wsw*C/Uabbe/Ww*E/Uabcd/Vq/Wsw*C/Uabbe/Ww*E/Uabcd/Vq/Wsw*C/Uabbe/Ww*E/Uabcd/Vq/Wsw*G/Uc*I/Ub*J/Ubcg*J/Ubcg*K/Ubcg#T2*B/Uabbe/Vqp/Wsw*C/Uabe/Ww*H/Ub*I/Ub*K/Ubcg#T7*Q/Ufck*R/Ujn*S/Ucdk#T5*E/Uabcd/Vqp/Wsw*G/Uab*P/Uc*I/Ub*J/Ubbg*K/Ubg*O/Ubbbb/Vqp/Ww*N/Ubcgnnnno#T8*Q/Uf*R/Ujn*K/Ucg*S/Uccll#T8*S/Uyyyyddbk+';

String _mockConfig2 =
    '#T*A1/Uzabcd/Vp1*B1/Uabcdz*E1/Uabcd*E2/Uabcd*E3/Uabcd*E4/Uabcd*E5/Uabcd*E6/Uabcd*E7/Uabcd*E8/Uabcd*E9/Uabcd*E10/Uabcd*E11/Uabcd*E12/Uabcd*E13/Uabcd*E14/Uabcd*E15/Uabcd*E16/Uabcd*L+#X1*Z1*Z2*Z3*Z4++';

String _mockConfig3 =
    '#T*E1/Uabc*E2/Uabcd*E3/Uabc*E4/Uabcd*E5/Uabcd*E6/Ua*E7/Uabcd*E8/Uabcd*E9/Uabc*K1/Uabcd*K2/Uabcd+';

String _mockConfig4 = '#T*A1/Vp1zq1zp2zq2zp3zq3z*L+#X1*Z1++';

Future<void> doLogGlobal(String className, String methodName, String value) async {
  if (!isLoggerEnable) return;

  debugPrint('$className : $methodName -> $value');

  if (Get.isRegistered<LoggerRepoImpl>()) {
    Get.find<LoggerRepoImpl>().addLog(EventBusConst.evenNewtLog, className, methodName, value);
  }
}
