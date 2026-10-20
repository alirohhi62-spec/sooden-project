import 'package:bms/core/utils/globals.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/new_connection_wraper/manage_new_locattion_data.dart';

import '../../result.dart';
import '../connection_manager/connection_manager_data_model.dart';
import '../connection_manager/connection_manager_impl.dart';
import 'fake_new_locattion_data_impl.dart';
import 'new_location_data_model.dart';

class NewLocationConnectionWrapper {

  late NewLocationDataModel _mNewLocationDataModel;
  late final MangeNewLocationData _mFakeNewData;
  late Function(Result) _mResultCallback;

  NewLocationConnectionWrapper(Function(Result) resultCallback) {
    _mResultCallback = resultCallback;
    _mFakeNewData = FakeNewLocationDataImpl(_mResultCallback);
  }

  connect(NewLocationDataModel newLocationDataModel) async {
    _mNewLocationDataModel = newLocationDataModel;
    if (testWithoutPanel) {
      manageFakeData();
    } else {
      _doSocketConnect();
    }
  }

  void manageFakeData() {
    var dataModel = ConnectionManagerDataModel();
    dataModel.newLocationDataModel = _mNewLocationDataModel;
    _mFakeNewData.startWorking(dataModel);
  }

  _doSocketConnect() {
    _mResultCallback.call(Result.loading());
    _logger('_doSocketConnect', 'Method Called.');
    ConnectionManagerImpl.instance.setData(_mResultCallback, model: _mNewLocationDataModel).connect();
  }

  void _logger(String key, String value) {
    doLogGlobal('new_location_connection_wrapper. H:$hashCode', key, value);
  }
}
