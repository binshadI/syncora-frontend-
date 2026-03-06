import 'dart:convert';
import 'package:frontend/models/verification_request_model.dart';
import 'package:http/http.dart' as http;

import '../config/config.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../services/shared_service.dart';
import '../models/register_request_model.dart';

class AuthService {
  static var client = http.Client();

  static Future<String?> login(LoginRequestModel model) async {
    print("login working..");

    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };

    var url = Uri.parse("${Config.apiURL}${Config.loginApi}");
    print("url : ${Config.apiURL}${Config.loginApi}");

    try {
      var response = await client.post(
        url,
        headers: requestHeaders,
        body: jsonEncode(model.toJson()),
      );

      var jsonData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        LoginResponseModel responseModel = LoginResponseModel.fromJson(jsonData);

        // ✅ Save login details (token) persistently via api_cache_manager
        await SharedService.setLoginDetails(responseModel);

        print("Login success. Token saved.");
        return null;
      } else {
        return jsonData["message"] ?? "Login failed";
      }
    } catch (e) {
      print("Login error: $e");
      return "Something went wrong. Please try again.";
    }
  }

  // Register ──────────────────────────────────────────────────────────────

  static Future<String?> register(RegisterRequestModel model) async {
    print("register page is working..");

    Map<String, String> requestHeader = {
      'Content-Type': 'application/json',
    };

    var url = Uri.parse("${Config.apiURL}${Config.registerApi}");

    try {
      var response = await client.post(
        url,
        headers: requestHeader,
        body: jsonEncode(model.toJson()),
      );

      var jsonData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return null;
      } else {
        return jsonData["message"] ?? "Registration failed";
      }
    } catch (e) {
      print("Register error: $e");
      return "Something went wrong. Please try again.";
    }
  }

  // Verification ──────────────────────────────────────────────────────────

  static Future<String?> verification(VerificationRequestModel model) async {
    print("verification is working..");

    Map<String, String> requestHeader = {
      'Content-Type': 'application/json',
    };

    var url = Uri.parse("${Config.apiURL}${Config.verifyOtp}");

    try {
      var response = await client.post(
        url,
        headers: requestHeader,
        body: jsonEncode(model.toJson()),
      );

      var jsonData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return null;
      } else {
        return jsonData["message"] ?? "Verification failed";
      }
    } catch (e) {
      print("Verification error: $e");
      return "Something went wrong. Please try again.";
    }
  }
}