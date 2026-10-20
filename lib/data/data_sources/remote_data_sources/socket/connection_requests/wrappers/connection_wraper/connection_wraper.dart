
  import '../../result.dart';

abstract class ConnectionWrapper {

  void requestForConnection(Function(Result) resultCallback);

}
