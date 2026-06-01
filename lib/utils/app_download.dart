import 'app_download_stub.dart' if (dart.library.html) 'app_download_web.dart'
    as platform;

enum AppInstallResult {
  pwaInstall,
  androidDownload,
  windowsDownload,
  alreadyInstalled,
  cancelled,
  unavailable,
}

Future<AppInstallResult> installCampusFixApp() async {
  final code = await platform.installCampusFixApp();
  return AppInstallResult.values.firstWhere(
    (result) => result.name == code,
    orElse: () => AppInstallResult.unavailable,
  );
}
