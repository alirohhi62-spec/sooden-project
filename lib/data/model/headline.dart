

import '../enums/headline_code.dart';

class Headline {
  HeadlineCode code;
  int? countOfDevices = 0;
  bool? active = false;

  Headline({
    required this.code,
    this.countOfDevices,
    this.active,
  });
}
