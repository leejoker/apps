import 'dart:convert';
import 'dart:io';

import 'package:apps/apps.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart' as dio;
import 'package:dio_range_download/dio_range_download.dart';

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
    final String filename =
        uri.toString().substring(uri.toString().lastIndexOf("/") + 1);
    try {
      print("start");
      bool isStarted = false;
      var startTime = DateTime.now();
      final savePath = config.downloadPath + path.separator + filename;
      final dio.Response res = await RangeDownload.downloadWithChunks(
          url, savePath, onReceiveProgress: (received, total) {
        if (!isStarted) {
          startTime = DateTime.now();
          isStarted = true;
        }
        if (total != -1) {
          print("${(received / total * 100).floor()}%");
        }
        if ((received / total * 100).floor() >= 100) {
          final duration = (DateTime.now().millisecondsSinceEpoch -
                  startTime.millisecondsSinceEpoch) /
              1000;
          print("${duration}s");
          print("${duration ~/ 60}m${duration % 60}s");
        }
      });
      print(res.statusCode);
      print(res.statusMessage);
      print(res.data);
    } catch (e) {
      print(e);
    }
    return Response.ok("please check the list");
  }
}
