import 'package:frontend/services/shared_service.dart';

class ApiService {

  static Future<Map<String, String>> getHeaders() async {

    var loginData = await SharedService.loginDetails();
    String? token = loginData?.accessToken;

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }
}