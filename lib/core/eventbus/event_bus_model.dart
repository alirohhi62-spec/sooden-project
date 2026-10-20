class EventBusModel{

  String? event;
  Object? data;

  EventBusModel({this.event, this.data});
}

class EventBusLogModel{
  String? event;
  String? className;
  String? methodName;
  String? value;

  EventBusLogModel({this.event, this.className, this.methodName, this.value});
}