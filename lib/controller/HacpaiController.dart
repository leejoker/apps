import 'dart:convert';

import 'package:appdownloader/appdownloader.dart';
import 'package:crypto/crypto.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

class HacpaiController extends ResourceController {
  HacpaiController(this.config);

  final Config config;

  Map map = {};

  void _getAllProps() {
    map["loginUrl"] = config.hacpai.loginUrl;
    map["checkinUrl"] = config.hacpai.checkinUrl;
    map["ylrUrl"] = config.hacpai.ylrUrl;
    map["username"] = config.hacpai.username;
    map["password"] =
        md5.convert(base64Decode(config.hacpai.password)).toString();
  }

  Future<String> _login() async {
    String result;
    _getAllProps();
    final data = {
      "nameOrEmail": "${map["username"]}",
      "userPassword": "${map["password"]}",
      "captcha": ""
    };
    final header = {
      "User-Agent":
          "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko",
      "Content-Type": "application/json"
    };
    try {
      result = await http
          .post(map["loginUrl"],
              headers: header,
              body: jsonEncode(data),
              encoding: Encoding.getByName("UTF-8"))
          .then((response) {
        print("响应状态： ${response.statusCode}");
        print("响应正文： ${response.body}");
        print("响应Headers： ${response.headers}");
        final responseMap = {};
        responseMap["body"] = response.body;
        responseMap["header"] = response.headers;
        return jsonEncode(responseMap);
      });
    } catch (e) {
      print(e);
    }
    return result;
  }

  @Operation.get()
  Future<Response> checkIn() async {
    String result;
    String checkinUrl = "";
    final String loginJson = await _login();
    final loginResult = jsonDecode(loginJson);
    final headers = loginResult["header"];
    print("LoginCookie: ${headers["set-cookie"]}");
    final header = {
      "User-Agent":
          "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko",
      "Cookie": headers["set-cookie"].toString()
    };
    try {
      result =
          await http.get(map["checkinUrl"], headers: header).then((response) {
        print("响应状态： ${response.statusCode}");
        //变更cookie信息
        header["Cookie"] = response.headers["set-cookie"];
        print("CheckinCookie: ${header["Cookie"]}");
        return response.body;
      });
      //处理html页面
      var document = parse(result);
      var aDom = document.querySelector("a[class='btn green']");
      print("DailyCheckinCookie: ${header["Cookie"]}");
      if (aDom != null) {
        checkinUrl = aDom.attributes["href"];
        result = await http.get(checkinUrl, headers: header).then((response) {
          print("响应状态： ${response.statusCode}");
          return response.body;
        });
      }
      document = parse(result);
      aDom = document.querySelector("a[class='btn']");
      result = aDom.innerHtml;
    } catch (e) {
      print(e);
    }
    return Response.ok(result);
  }
}
