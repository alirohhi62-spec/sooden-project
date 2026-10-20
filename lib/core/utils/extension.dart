
import 'package:bms/core/utils/util.dart';
import 'package:sizer/sizer.dart';

extension DimenExt on double {
  double get dp {
    switch (Utils.screenType()) {
      case MobileSize.small:
        return calculatedSize(2.7);
      case MobileSize.normal:
        return calculatedSize(3.2);
      case MobileSize.large:
        return calculatedSize(3.5);
    }
  }

  double get sp {
    switch (Utils.screenType()) {
      case MobileSize.small:
        return calculatedSize(2.7);
      case MobileSize.normal:
        return calculatedSize(3.5);
      case MobileSize.large:
        return calculatedSize(4);
    }
  }

  double calculatedSize(double size) {
    return Utils.isTablet()
        ? this * (SizerUtil.width / 5) / 100
        : this * (SizerUtil.width / size) / 100;
  }
}
