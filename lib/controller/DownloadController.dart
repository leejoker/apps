import 'dart:convert';
import 'dart:io';

import 'package:appdownloader/appdownloader.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class DownloadController extends ResourceController {
  DownloadController(this.config);

  final Config config;

  String getUrlByFilename(FileSystemEntity file, Config config) {
    return "${config.protocol}://${config.host}${config.uri}${path.basename(file.path)}";
  }

  @Operation.get()
  Future<Response> getAllSoft() async {
    //list files in downloadPath
    final downloadPath = config.downloadPath;
    final file = Directory(downloadPath);
    final map = <String, List>{};
    final nameList = <String>[];
    final urlList = <String>[];
    //put file names and urls into the map
    await file?.list()?.forEach((f) {
      nameList.add(path.basenameWithoutExtension(f.path));
      urlList.add(getUrlByFilename(f, config));
    });
    map["nameList"] = nameList;
    map["urlList"] = urlList;
    //transfer to json
    final json = jsonEncode(map);
    return Response.ok(json);
  }

  @Operation.get("url")
  Future<Response> getSoftDownloadUrl(@Bind.path("url") String url) async {
    var decodeUrl = String.fromCharCodes(base64Decode(url));
    decodeUrl = Uri.decodeComponent(decodeUrl);
    final uri = Uri.parse(decodeUrl);
    //download files by url
    String filename;
    double progress = 0.0;
    try {
      //TODO 增加多线程下载的处理
      final _client = http.Client();
      final req = http.Request('get', uri);
      final http.StreamedResponse r = await _client.send(req);
      print(r.statusCode);
      //设置下载相关参数
      double curLen = 0.0;
      final totalLen = r.contentLength;
      final ds = <int>[1024 * 1024 * 3];
      final cd = r.headers["Content-Disposition"];
      if (cd != null) {
        filename = cd.contains("filename") ? cd.split("=")[1] : "";
      } else {
        filename =
            uri.toString().substring(uri.toString().lastIndexOf("/") + 1);
      }
      //开始监听下载
      r.stream.listen((List<int> d) {
        ds.addAll(d);
        curLen += ds.length;
        progress = curLen * 100 / totalLen;
        File(config.downloadPath + path.separator + filename)
            .writeAsBytesSync(ds, mode: FileMode.append, flush: true);
        print("current progress: ${progress.toStringAsFixed(2)}%");
        ds.clear();
      }, onDone: () {
        print("download file over!");
        _client?.close();
      });
    } catch (e) {
      print(e);
    }

    return Response.ok("please check the list");
  }
}
