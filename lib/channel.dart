import 'package:appdownloader/controller/DownloadController.dart';

import 'appdownloader.dart';

class AppdownloaderChannel extends ApplicationChannel {
  Config config;

  @override
  Future prepare() async {
    logger.onRecord.listen(
        (rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
    config = Config(options.configurationFilePath);
  }

  @override
  Controller get entryPoint {
    final router = Router();

    router.route("/").linkFunction((request) async {
      return Response.ok("Leejoker's AppDownloader");
    });
    router.route("/down/[:url]").link(() => DownloadController(config));

    return router;
  }
}

class Config extends Configuration {
  Config(String path) : super.fromFile(File(path));
  String downloadPath;
  String host;
  String uri;
  String protocol;
}
