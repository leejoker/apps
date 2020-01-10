import 'dart:convert';

import 'package:apps/apps.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart' hide Response;
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart';

class HacpaiController extends ResourceController {
  HacpaiController(this.config);

  final Config config;

  Map map = {};

  final Dio dio = Dio();

  final Map<String, String> loginHeader = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko",
    "Content-Type": "application/json"
  };

  final Map<String, String> checkInHeader = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko",
    "Referer": "https://hacpai.com/activity/checkin"
  };

  final Map<String, String> logoutHeader = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko"
  };

  /// 登录
  Future<String> _login(username, password) async {
    String result;
    final data = {
      "nameOrEmail": "${username}",
      "userPassword": "${password}",
      "captcha": ""
    };
    final Options options = Options(headers: loginHeader);
    try {
      final loginUrl =
          "${config.hacpai.loginUrl}?curTime=${DateTime.now().microsecondsSinceEpoch}";
      result = (await dio.post(loginUrl, data: data, options: options))
          .data
          .toString();
    } catch (e) {
      print(e);
    }
    return result;
  }

  /// 注销
  Future<String> _logout() async {
    String result;
    final Options options = Options(headers: logoutHeader);
    try {
      result = (await dio.get(config.hacpai.logoutUrl, options: options))
          .statusMessage
          .toString();
    } catch (e) {
      print(e);
    }
    return result;
  }

  /// 签到
  Future<String> _checkIn() async {
    String result;
    final Options options = Options(headers: checkInHeader);
    try {
      final checkInUrl =
          "${config.hacpai.checkinUrl}?curTime=${DateTime.now().microsecondsSinceEpoch}";
      result = (await dio.get(checkInUrl, options: options)).data.toString();
      //处理html页面
      var document = parse(result);
      var aDom = document.querySelector("a[class='btn green']");
      if (aDom != null) {
        final dailyCheckInUrl =
            "${aDom.attributes["href"]}&curTime=${DateTime.now().microsecondsSinceEpoch}";
        result =
            (await dio.get(dailyCheckInUrl, options: options)).data.toString();
      }
      document = parse(result);
      aDom = document.querySelector("a[class='btn']");
      result = aDom?.innerHtml;
    } catch (e) {
      print(e);
    }
    return result;
  }

  CookieManager _createCookieManager() {
    final cookieJar = CookieJar();
    final cookieManager = CookieManager(cookieJar);
    return cookieManager;
  }

  @Operation.get()
  Future<Response> checkInBatch() async {
    final jsonStr = File("${config.hacpai.jsonFile}").readAsStringSync();
    final map = json.decode(jsonStr);
    final List userList = map["accounts"] as List;
    final resultMap = {};
    //添加cookieManager拦截器
    dio.interceptors.add(_createCookieManager());
    for (var user in userList) {
      final username = user["username"];
      final password =
          md5.convert(base64Decode(user["password"].toString())).toString();
      var result = await _login(username, password);
      //输出登录状态
      print("${username} : ${result}");
      result = await _checkIn();
      //输出签到状态
      print(result);
      resultMap[username] = result;
      //注销登录
      result = await _logout();
      print(result);
    }
    return Response.ok(jsonEncode(resultMap));
  }
}
