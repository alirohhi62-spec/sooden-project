
import 'package:dio/dio.dart';

Dio buildDioClient(String base ) {
final dio = Dio()..options = BaseOptions(baseUrl: base);

dio.interceptors.addAll([
  // TokenInterceptor(),

]);

/*Alice alice = Alice(showNotification: true);
dio.interceptors.add(alice.getDioInterceptor());*/
return dio;
}