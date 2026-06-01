import 'dart:js_interop';

import 'package:web/web.dart' as web;

const _androidApkUrl = String.fromEnvironment('CAMPUSFIX_ANDROID_APK_URL');
const _windowsAppUrl = String.fromEnvironment('CAMPUSFIX_WINDOWS_APP_URL');

@JS('campusfixInstallApp')
external JSPromise<JSString> _campusfixInstallApp();

Future<String> installCampusFixApp() async {
  if (_isAndroid()) {
    _downloadAndroidApk();
    return 'androidDownload';
  }

  if (_isIos()) {
    return 'unavailable';
  }

  try {
    final result = (await _campusfixInstallApp().toDart).toDart;
    if (result != 'unavailable') return result;
  } catch (_) {
    // Fall through to the Windows package when browser install is unavailable.
  }

  if (_isWindows()) {
    _downloadWindowsApp();
    return 'windowsDownload';
  }

  return 'unavailable';
}

void _downloadAndroidApk() {
  final href =
      _androidApkUrl.isNotEmpty ? _androidApkUrl : 'downloads/CampusFix.apk';
  final anchor = web.HTMLAnchorElement()
    ..href = href
    ..style.display = 'none';

  if (_androidApkUrl.isEmpty) {
    anchor.download = 'CampusFix.apk';
  }

  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}

void _downloadWindowsApp() {
  final href = _windowsAppUrl.isNotEmpty
      ? _windowsAppUrl
      : 'https://github.com/Bimbo2018-Dev/CampusFix/releases/latest/download/CampusFix-Windows.zip';
  final anchor = web.HTMLAnchorElement()
    ..href = href
    ..style.display = 'none';

  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}

bool _isAndroid() {
  return web.window.navigator.userAgent.toLowerCase().contains('android');
}

bool _isIos() {
  final userAgent = web.window.navigator.userAgent.toLowerCase();
  return userAgent.contains('iphone') ||
      userAgent.contains('ipad') ||
      userAgent.contains('ipod');
}

bool _isWindows() {
  return web.window.navigator.userAgent.toLowerCase().contains('windows');
}
