import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/baseapiservice.dart';
import '../config/config.dart';

class ChatService {
  static const String baseUrl = '${Config.apiURL}';

  static Future<Map<String, String>> getRoomId(String friendId) async {
    final headers = await ApiService.getHeaders();
    final response = await http.post(
      Uri.parse('${Config.apiURL}${Config.getroomId}'),
      headers: headers,
      body: jsonEncode({'friendId': friendId}),
    );

    print("STATUS: ${response.statusCode}"); // 👈
    print("BODY: ${response.body}");         // 👈

    final data = jsonDecode(response.body);
    return {
      'roomId': data['friendreqId'],
      'senderId': data['userId'],
    };
  }
}