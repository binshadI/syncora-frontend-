import 'dart:convert';

import '../config/config.dart';
import '../models/addtocontact_response_model.dart';
import '../services/baseapiservice.dart';
import '../models/addtocontact_response_model.dart';
import '../models/addtocontact_request_model.dart';

import 'package:http/http.dart' as http;


class FriendrequestService {
  static Future<String?> Friendrequest(FriendreqRequestModel model) async{
    var headers = await ApiService.getHeaders();
    var response = await http.post(
      Uri.parse("${Config.apiURL}${Config.Friendrequest}"),
      headers: headers,
        body: jsonEncode(model.toJson()),
    );

    var jsonData = jsonDecode(response.body);

    if(response.statusCode == 200){
      return FriendreqResponsetModel.fromJson(jsonData).message;
    }else {
      throw Exception(jsonData["message"] ?? "somthing went wrong..");
    }
  }
}