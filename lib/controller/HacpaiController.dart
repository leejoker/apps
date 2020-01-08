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

  void _getAllProps() {
    map["loginUrl"] = config.hacpai.loginUrl;
    map["checkinUrl"] = config.hacpai.checkinUrl;
    map["ylrUrl"] = config.hacpai.ylrUrl;
    map["username"] = config.hacpai.username;
    map["password"] =
        md5.convert(base64Decode(config.hacpai.password)).toString();
    map["Referer"] = config.hacpai.checkinRefUrl;
  }

  final Map<String, String> loginHeader = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko",
    "Content-Type": "application/json"
  };

  Future<String> _login() async {
    String result;
    _getAllProps();
    final data = {
      "nameOrEmail": "${map["username"]}",
      "userPassword": "${map["password"]}",
      "captcha": ""
    };

    dio.interceptors.add(CookieManager(cookieJar));
    final Options options = Options(headers: loginHeader);
    try {
      result = (await dio.post(map["loginUrl"].toString(),
              data: data, options: options))
          .data
          .toString();
    } catch (e) {
      print(e);
    }
    return result;
  }

  @Operation.get()
  Future<Response> checkIn() async {
    String result;
    result = await _login();
    print("login result: ${result}");

    final checkinHeader = {
      "User-Agent":
          "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko",
      "Referer": map["Referer"]
    };

    final Options options = Options(headers: checkinHeader);
    try {
      result = (await dio.get(map["checkinUrl"].toString(), options: options))
          .data
          .toString();
      print("checkin result: ${result}");

      //处理html页面
      var document = parse(result);
      var aDom = document.querySelector("a[class='btn green']");
      if (aDom != null) {
        print("daily-chein url : ${aDom.attributes["href"]}");
        result = (await dio.get(aDom.attributes["href"], options: options))
            .data
            .toString();
      }
      print("daily-checkin result: ${result}");
      document = parse(result);
      aDom = document.querySelector("a[class='btn']");
      result = aDom?.innerHtml;
    } catch (e) {
      print(e);
    }
    return Response.ok(result);
  }
}
