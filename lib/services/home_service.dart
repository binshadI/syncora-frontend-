import 'dart:convert';
import '../config/config.dart';
import '../services/baseapiservice.dart';
import '../models/home_response_model.dart';
import 'package:http/http.dart' as http;

class HomeService {
  static Future<List<Contact>> getContacts() async {
    var headers = await ApiService.getHeaders();
    var response = await http.get(
      Uri.parse("${Config.apiURL}${Config.home}"),
      headers: headers,
    );

    var jsonData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return HomeResponse.fromJson(jsonData).contacts;
    } else {
      throw Exception(jsonData["message"] ?? "Failed to load contacts");
    }
  }
}