

import '../../../result.dart';
import '../connection_manager_data_model.dart';

abstract class ManageGettingConfig {

  void setData(ConnectionManagerDataModel dataModel, Function(Result) resultCallback);

  void requestIp();

  void requestQueryFloorsCount();

  void requestOneFloor();
  
  void onUserData();

  /// Expected : %44:17:93:3a:1e:37+

  void onIpReceived(List<int> data);

  void onDataFloorReceived(List<int> data);

  /// Expected data #T1#T2#T3#T4++ Or #T++
  void onQueryFloorsCountReceived(List<int> data);

  /// Expected data :
  /// 1. #T*A1/Uaaaaaaaaaa/Vp1*L+#X1*Z1++
  /// 2. #T0*A/Uaabbcd/Vqqpp/Wsw*B/Uaabbbdek/Vqp/Wsw*C/Uabde/Ww*E/Uabcd/Vqp/Wsw*G/Ub*I/Ub*J/Ubcg*K/Ubcg++
  /// 3. #T1*B/Uaabbcd/Vq/Wsw*C/Uabbe/Ww*E/Uabcd/Vq/Wsw*C/Uabbe/Ww*E/Uabcd/Vq/Wsw*C/Uabbe/Ww*E/Uabcd/Vq/Wsw*G/Uc*I/Ub*J/Ubcg*J/Ubcg*K/Ubcg++

  void onOneFloorDataReceived(List<int> data);

  void changeMode(ConnectionManagerModeEnum newMode);

  void onDataListener(List<int> data );

  void startTheJob();

}