import 'dart:convert';

import 'package:appdownloader/appdownloader.dart';
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
  final CookieJar cookieJar = CookieJar();

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

  Future<String> _login(username, password) async {
    String result;
    final data = {
      "nameOrEmail": "${username}",
      "userPassword": "${password}",
      "captcha": ""
    };

    dio.interceptors.add(CookieManager(cookieJar));
    final Options options = Options(headers: loginHeader);
    try {
      result =
          (await dio.post(config.hacpai.loginUrl, data: data, options: options))
              .data
              .toString();
    } catch (e) {
      print(e);
    }
    return result;
  }

  Future<String> _checkIn() async {
    String result;
    final Options options = Options(headers: checkInHeader);
    try {
      result = (await dio.get(config.hacpai.checkinUrl, options: options))
          .data
          .toString();
      //处理html页面
      var document = parse(result);
      var aDom = document.querySelector("a[class='btn green']");
      if (aDom != null) {
        print("daily-chein url : ${aDom.attributes["href"]}");
        result = (await dio.get(aDom.attributes["href"], options: options))
            .data
            .toString();
      }
      document = parse(result);
      aDom = document.querySelector("a[class='btn']");
      result = aDom?.innerHtml;
    } catch (e) {
      print(e);
    }
    return result;
  }

  @Operation.get()
  Future<Response> checkInBatch() async {
    final jsonStr = File("${config.hacpai.jsonFile}").readAsStringSync();
    final map = json.decode(jsonStr);
    final List userList = map["accounts"] as List;
    final resultMap = {};
    for (var user in userList) {
      final username = user["username"];
      final password =
          md5.convert(base64Decode(user["password"].toString())).toString();
      var result = await _login(username, password);
      //输出登录状态
      print(result);
      result = await _checkIn();
      //输出签到状态
      print(result);
      resultMap[username] = result;
    }
    return Response.ok(jsonEncode(resultMap));
  }
}
