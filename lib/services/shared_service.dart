import 'dart:convert';

import 'package:api_cache_manager/api_cache_manager.dart';
import 'package:api_cache_manager/models/cache_db_model.dart';
import 'package:flutter/cupertino.dart';

import '../models/login_response_model.dart';

class SharedService {

  static Future<bool> isLoggedIn() async {
    return await APICacheManager()
        .isAPICacheKeyExist("login_details");
  }

  static Future<LoginResponseModel?> loginDetails() async {
    var isCacheKeyExist =
    await APICacheManager().isAPICacheKeyExist("login_details");

    if (isCacheKeyExist) {
      var cacheData =
      await APICacheManager().getCacheData("login_details");

      return LoginResponseModel.fromJson(
        jsonDecode(cacheData.syncData),
      );
    }

    return null;
  }

  static Future<void> setLoginDetails(
      LoginResponseModel loginResponse,
      ) async {
    APICacheDBModel cacheModel = APICacheDBModel(
      key: "login_details",
      syncData: jsonEncode(loginResponse.toJson()),
    );

    await APICacheManager().addCacheData(cacheModel);
  }


  static Future<void> logout(BuildContext context) async {
    await APICacheManager().deleteCache("login_details");

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/auth/login',
          (route) => false,
    );
  }
}
