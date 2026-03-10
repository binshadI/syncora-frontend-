import 'dart:convert';
import '../models/notificationResponsetModel.dart';
import '../services/baseapiservice.dart';
import 'package:http/http.dart' as http;
import '../config/config.dart';

class NotificationService {

  // GET - fetch pending requests
  static Future<List<Request>> getPendingRequests() async {
    final headers = await ApiService.getHeaders();

    final response = await http.get(
      Uri.parse("${Config.apiURL}${Config.notification}"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return (body["request"] as List)
          .map((e) => Request.fromJson(e))
          .toList();
    }
    return [];
  }

  // PUT
  static Future<bool> updateFriendRequest(String reqId, String status) async {
    final headers = await ApiService.getHeaders();

    final response = await http.put(
      Uri.parse('${Config.apiURL}${Config.status}$reqId'),
      headers: headers,
      body: jsonEncode({'status': status}),
    );

    return response.statusCode == 200;
  }
}