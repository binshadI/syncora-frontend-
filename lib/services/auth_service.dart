import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/config.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../services/shared_service.dart';
import '../models/register_request_model.dart';
import '../models/register_response_model.dart';


class AuthService {
  static var client = http.Client();

  static Future<String?> login(LoginRequestModel model) async {
    print("login working..");
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };

    var url = Uri.parse("${Config.apiURL}${Config.loginApi}");

    print("url : ${Config.apiURL}${Config.loginApi}");

    var response = await client.post(
      url,
      headers: requestHeaders,
      body: jsonEncode(model.toJson()),
    );


    var jsonData = jsonDecode(response.body);
    if (response.statusCode == 200) {

      // Convert JSON string to LoginResponseModel object
      LoginResponseModel responseModel =
      LoginResponseModel.fromJson(jsonData);


      // Save login details (like token) in local storage

      await SharedService.setLoginDetails(responseModel);

      return null;
    } else {
      return jsonData["message"];
    }
  }


  //register section ..._________________


  static Future<String?>register(RegisterRequestModel model) async {
    print("register page is working..");

    Map<String, String> requestHeader = {
      'Content-Type': 'application/json',
    };

    var url = Uri.parse("${Config.apiURL}${Config.registerApi}");

    var response = await client.post(
      url,
      headers: requestHeader,
      body: jsonEncode(model.toJson()),
    );

    var jsonData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      RegisterResponseModel responseModel =
        RegisterResponseModel.fromJson(jsonData);
      return null;
    } else {
      return jsonData["message"];
    }
  }
}
