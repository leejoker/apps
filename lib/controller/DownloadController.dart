import 'dart:convert';

import 'package:appdownloader/appdownloader.dart';
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
    final uri = Uri.parse(url);
    //download files by url
    String filename;
    await HttpClient()
        .getUrl(uri)
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) {
      final cd = response.headers.value("Content-Disposition");
      filename = cd.contains("filename") ? cd.split("=")[1] : "";
      response.pipe(
          File(config.downloadPath + path.separator + filename).openWrite());
    });
    final u = getUrlByFilename(File(filename), config);
    return Response.ok("""<a href='${u}'>${filename}</a>""");
  }
}
