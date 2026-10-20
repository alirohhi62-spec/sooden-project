import 'package:bms/data/data_sources/remote_data_sources/socket/socket.dart';
import 'package:bms/domain/usecases/send_data/send_data_socket_usecase.dart';

import '../../../core/utils/globals.dart';

/// قبلاً هر فرمانی که در ۲۰۰ میلی‌ثانیه بعد از فرمان قبلی می‌آمد بی‌صدا حذف می‌شد.
/// حالا همه‌ی فرمان‌ها به صف سوکت می‌روند و با فاصله‌ی مناسب ارسال می‌شوند.
class SendDataSocketUsecaseImpl extends SendDataSocketUsecase {
  final Socket _mSocket = Socket.instance;

  @override
  send(List<int> command) {
    _logger("send", 'Method called command:${command.join('-')}');
    _mSocket.send(command);
  }

  @override
  sendString(String message) {
    _logger("sendString", 'Method called message: $message');
    _mSocket.sendString(message);
  }

  void _logger(String key, String value) {
    doLogGlobal('send_data_socket_usecase_impl. H:$hashCode', key, value);
  }
}
