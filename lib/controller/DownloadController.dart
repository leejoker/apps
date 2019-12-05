import 'dart:convert';

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
    double finalProgress = 0.0;
    try {
      final _client = http.Client();
      final req = http.Request('get', uri);
      http.StreamedResponse r = await _client.send(req);
      print(r.statusCode);
      final ds = <int>[];
      r.stream.listen((List<int> d) {
        ds.addAll(d);
        final curLen = ds.length;
        final totalLen = r.contentLength;
        progress = curLen * 100 / totalLen;
        if(progress - finalProgress > 1){
          print("current progress: ${progress.toStringAsFixed(2)}%");
          finalProgress = progress;
        }
      }, onDone: () {
        final cd = r.headers["Content-Disposition"];
        if (cd != null) {
          filename = cd.contains("filename") ? cd.split("=")[1] : "";
        } else {
          filename =
              uri.toString().substring(uri.toString().lastIndexOf("/") + 1);
        }
        File(config.downloadPath + path.separator + filename).writeAsBytes(ds);
        _client?.close();
      });
    } catch (e) {
      print(e);
    }

    return Response.ok("please check the list");
  }
}
