import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRReaderScreen extends StatefulWidget {
  late Function(String ssid, String password) callback;

  QRReaderScreen(this.callback, {super.key});

  @override
  State<StatefulWidget> createState() => _QRReaderScreenState();
}

class _QRReaderScreenState extends State<QRReaderScreen> {
  // قبلاً کنترلر در هر بار ساخت صفحه از نو ساخته می‌شد و آزاد نمی‌شد
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_handled || capture.barcodes.isEmpty) return;
          final String? raw = capture.barcodes.first.rawValue;
          if (raw == null) return;

          try {
            String ssid = raw.substring(raw.indexOf('S:') + 2, raw.indexOf(';', raw.indexOf('S:') + 2));
            String pass = raw.substring(raw.indexOf('P:') + 2, raw.indexOf(';', raw.indexOf('P:') + 2));

            _handled = true;
            widget.callback.call(ssid, pass);
            Get.back();
          } catch (e) {
            Get.snackbar('خطا', 'این کیو آر معتبر نمی باشد');
          }
        },
      ),
    );
  }
}
