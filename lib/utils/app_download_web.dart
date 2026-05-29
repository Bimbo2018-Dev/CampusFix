import 'dart:js_interop';

import 'package:web/web.dart' as web;

const _androidApkUrl = String.fromEnvironment('CAMPUSFIX_ANDROID_APK_URL');

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
    return (await _campusfixInstallApp().toDart).toDart;
  } catch (_) {
    return 'unavailable';
  }
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

bool _isAndroid() {
  return web.window.navigator.userAgent.toLowerCase().contains('android');
}

bool _isIos() {
  final userAgent = web.window.navigator.userAgent.toLowerCase();
  return userAgent.contains('iphone') ||
      userAgent.contains('ipad') ||
      userAgent.contains('ipod');
}
