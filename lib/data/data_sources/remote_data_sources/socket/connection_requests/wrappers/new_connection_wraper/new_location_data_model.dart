  class NewLocationDataModel {
  String _locationName="";
  String? _ipStatic;

  NewLocationDataModel(String locationName, String? ipStatic){
    _locationName = locationName;
    _ipStatic = ipStatic;
  }

  String get locationName => _locationName;

  set locationName(String value) {
    _locationName = value;
  }

  String? get ipStatic => _ipStatic;

  set ipStatic(String? value) {
    _ipStatic = value;
  }
}