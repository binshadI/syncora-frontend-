import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/baseapiservice.dart';
import '../services/shared_service.dart';
import '../config/config.dart';

class ChatService {
  static const String baseUrl = '${Config.apiURL}';

  // ── Decode a field from JWT token ──────────────────────────────
  static Future<String> _getFieldFromToken(List<String> fieldNames) async {
    try {
      final details = await SharedService.loginDetails();
      if (details == null) return '';
      final parts = details.accessToken.split('.');
      if (parts.length != 3) return '';
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      print('🔑 JWT payload in ChatService: $payload');
      for (final field in fieldNames) {
        if (payload[field] != null && payload[field].toString().isNotEmpty) {
          return payload[field].toString();
        }
      }
    } catch (e) {
      print('❌ JWT decode error in ChatService: $e');
    }
    return '';
  }

  static Future<Map<String, String>> getRoomId(String friendId) async {
    final headers = await ApiService.getHeaders();
    final response = await http.post(
      Uri.parse('${Config.apiURL}${Config.getroomId}'),
      headers: headers,
      body: jsonEncode({'friendId': friendId}),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    final data = jsonDecode(response.body);

    // ✅ Get senderName from JWT since API doesn't return it
    final senderName = await _getFieldFromToken([
      'name', 'username', 'userName', 'fullName', 'displayName'
    ]);
    print('👤 senderName from token: $senderName');

    return {
      'roomId'    : data['friendreqId'] ?? '',
      'senderId'  : data['userId']      ?? '',
      'friendId'  : data['friendId']    ?? friendId,
      'senderName': senderName,
    };
  }
}